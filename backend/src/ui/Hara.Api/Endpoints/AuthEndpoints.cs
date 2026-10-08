using Hara.Api.RateLimiting;
using Hara.Application.Auth.Commands.Login;
using Hara.Application.Auth.Commands.Logout;
using Hara.Application.Auth.Commands.RefreshToken;
using Hara.Application.Auth.Commands.RegisterOwner;
using Hara.Application.Auth.Commands.RegisterStaff;
using MediatR;

namespace Hara.Api.Endpoints;

public static class AuthEndpoints
{
    public static IEndpointRouteBuilder MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/auth/login", async (LoginCommand command, ISender sender, CancellationToken cancellationToken) =>
            {
                var result = await sender.Send(command, cancellationToken);
                return Results.Ok(result);
            })
            .WithTags("Auth")
            .WithName("Login")
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.Login);

        app.MapPost("/api/auth/register-owner", async (RegisterOwnerCommand command, ISender sender, CancellationToken cancellationToken) =>
                Results.Created((string?)null, await sender.Send(command, cancellationToken)))
            .WithTags("Auth")
            .WithName("RegisterOwner")
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.Registrations);

        app.MapPost("/api/auth/register-staff", async (RegisterStaffCommand command, ISender sender, CancellationToken cancellationToken) =>
                Results.Created((string?)null, await sender.Send(command, cancellationToken)))
            .WithTags("Auth")
            .WithName("RegisterStaff")
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.Registrations);

        app.MapPost("/api/auth/refresh", async (RefreshTokenCommand command, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(command, cancellationToken)))
            .WithTags("Auth")
            .WithName("RefreshToken")
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.Login);

        app.MapPost("/api/auth/logout", async (LogoutCommand command, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(command, cancellationToken);
                return Results.NoContent();
            })
            .WithTags("Auth")
            .WithName("Logout")
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.Login);

        return app;
    }
}
