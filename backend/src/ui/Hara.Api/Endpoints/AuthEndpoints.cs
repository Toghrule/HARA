using Hara.Api.RateLimiting;
using Hara.Application.Auth.Commands.Login;
using Hara.Application.Auth.Commands.Logout;
using Hara.Application.Auth.Commands.RefreshToken;
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
