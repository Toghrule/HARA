using Hara.Application.ChangeRequests.Commands.ReviewChangeRequest;
using Hara.Application.ChangeRequests.Queries.GetChangeRequests;
using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Api.Endpoints;

/// <summary>The admin's side of owners' change requests (the owner's side is in <see cref="VenueEndpoints"/>).</summary>
public static class ChangeRequestsEndpoints
{
    public static IEndpointRouteBuilder MapChangeRequestsEndpoints(this IEndpointRouteBuilder app)
    {
        var admin = app.MapGroup("/api/admin/change-requests")
            .WithTags("Admin.ChangeRequests")
            .RequireAuthorization("Admin");

        admin.MapGet("/", async (ChangeRequestStatus? status, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetChangeRequestsQuery(status), cancellationToken)))
            .WithName("AdminGetChangeRequests");

        admin.MapPatch("/{id:guid}/status", async (Guid id, ReviewChangeRequestBody body, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new ReviewChangeRequestCommand(id, body.Decision, body.AdminNote), cancellationToken)))
            .WithName("AdminReviewChangeRequest");

        return app;
    }

    private sealed record ReviewChangeRequestBody(ChangeRequestStatus Decision, string? AdminNote);
}
