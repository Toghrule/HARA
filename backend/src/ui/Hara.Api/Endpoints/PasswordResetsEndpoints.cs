using Hara.Api.RateLimiting;
using Hara.Application.PasswordResets;
using Hara.Domain.Members;
using MediatR;

namespace Hara.Api.Endpoints;

/// <summary>
/// An owner who forgot their password: the app asks, the admin approves after checking it is the owner, and the same phone
/// then sets the new password. The status and the final step take the request's secret in the body, never in the address.
/// </summary>
public static class PasswordResetsEndpoints
{
    public static IEndpointRouteBuilder MapPasswordResetsEndpoints(this IEndpointRouteBuilder app)
    {
        var reset = app.MapGroup("/api/auth/password-reset")
            .WithTags("Auth")
            .AllowAnonymous();

        reset.MapPost("/request", async (RequestPasswordResetCommand command, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(command, cancellationToken)))
            .WithName("RequestPasswordReset")
            .RequireRateLimiting(RateLimitPolicies.PasswordResetRequests);

        reset.MapPost("/status", async (GetPasswordResetStatusQuery query, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(query, cancellationToken)))
            .WithName("GetPasswordResetStatus")
            .RequireRateLimiting(RateLimitPolicies.PasswordResetChecks);

        reset.MapPost("/complete", async (CompletePasswordResetCommand command, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(command, cancellationToken);
                return Results.NoContent();
            })
            .WithName("CompletePasswordReset")
            .RequireRateLimiting(RateLimitPolicies.Login);

        var admin = app.MapGroup("/api/admin/password-resets")
            .WithTags("Admin.PasswordResets")
            .RequireAuthorization("Admin");

        admin.MapGet("/", async (PasswordResetStatus? status, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetPasswordResetRequestsQuery(status), cancellationToken)))
            .WithName("AdminGetPasswordResets");

        admin.MapPost("/{id:guid}/approve", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new DecidePasswordResetCommand(id, Approve: true), cancellationToken)))
            .WithName("AdminApprovePasswordReset");

        admin.MapPost("/{id:guid}/reject", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new DecidePasswordResetCommand(id, Approve: false), cancellationToken)))
            .WithName("AdminRejectPasswordReset");

        return app;
    }
}
