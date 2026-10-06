using System.Globalization;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;

namespace Hara.Api.RateLimiting;

/// <summary>Names of the rate-limit policies applied to anonymous endpoints.</summary>
public static class RateLimitPolicies
{
    public const string Reservations = "Reservations";
    public const string Submissions = "Submissions";
}

public sealed class RateLimitPolicyOptions
{
    public int PermitLimit { get; set; }

    public int WindowMinutes { get; set; }
}

public static class RateLimitingExtensions
{
    /// <summary>
    /// Limits how often one client IP can call the anonymous "create" endpoints, so a script can't
    /// flood the venues' reservations or the admin's submission queue. Limits come from the
    /// <c>RateLimiting:{Policy}</c> configuration section (permits per window, in minutes).
    /// </summary>
    /// <remarks>
    /// The partition key is the connection's remote IP. Behind a reverse proxy every request would
    /// share the proxy's IP, so forwarded-headers handling must be configured at deployment time.
    /// </remarks>
    public static IServiceCollection AddHaraRateLimiting(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            options.OnRejected = WriteTooManyRequestsAsync;

            AddPerIpPolicy(options, configuration, RateLimitPolicies.Reservations, defaultPermitLimit: 5);
            AddPerIpPolicy(options, configuration, RateLimitPolicies.Submissions, defaultPermitLimit: 3);
        });

        return services;
    }

    private static void AddPerIpPolicy(RateLimiterOptions options, IConfiguration configuration, string policyName, int defaultPermitLimit)
    {
        var settings = new RateLimitPolicyOptions { PermitLimit = defaultPermitLimit, WindowMinutes = 60 };
        configuration.GetSection($"RateLimiting:{policyName}").Bind(settings);

        options.AddPolicy(policyName, httpContext => RateLimitPartition.GetFixedWindowLimiter(
            httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = settings.PermitLimit,
                Window = TimeSpan.FromMinutes(settings.WindowMinutes),
                QueueLimit = 0,
            }));
    }

    private static async ValueTask WriteTooManyRequestsAsync(OnRejectedContext context, CancellationToken cancellationToken)
    {
        var response = context.HttpContext.Response;
        response.StatusCode = StatusCodes.Status429TooManyRequests;

        if (context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfter))
        {
            response.Headers.RetryAfter = ((int)Math.Ceiling(retryAfter.TotalSeconds)).ToString(CultureInfo.InvariantCulture);
        }

        // Same shape as the error responses ExceptionHandlingMiddleware writes.
        response.ContentType = "application/problem+json";
        await response.WriteAsJsonAsync(
            new { title = "Too many attempts. Please try again later.", status = StatusCodes.Status429TooManyRequests },
            cancellationToken);
    }
}
