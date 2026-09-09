using Hara.Application.Auth.Commands.Login;
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
            .AllowAnonymous();

        return app;
    }
}
