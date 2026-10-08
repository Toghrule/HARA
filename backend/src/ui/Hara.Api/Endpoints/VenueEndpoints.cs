using Hara.Application.Venue.Commands.RemoveStaff;
using Hara.Application.Venue.Commands.ReviewStaff;
using Hara.Application.Venue.Queries.GetMyVenueStatus;
using Hara.Application.Venue.Queries.GetVenueStaff;
using MediatR;

namespace Hara.Api.Endpoints;

/// <summary>
/// What restaurant owners and waiters do in the app. Everything here is scoped to the restaurant the
/// signed-in person is approved for, which is looked up in the database on every request.
/// </summary>
public static class VenueEndpoints
{
    public static IEndpointRouteBuilder MapVenueEndpoints(this IEndpointRouteBuilder app)
    {
        var venue = app.MapGroup("/api/venue")
            .WithTags("Venue")
            .RequireAuthorization("VenueMember");

        venue.MapGet("/me", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetMyVenueStatusQuery(), cancellationToken)))
            .WithName("GetMyVenueStatus");

        var staff = venue.MapGroup("/staff").RequireAuthorization("Owner");

        staff.MapGet("/", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetVenueStaffQuery(), cancellationToken)))
            .WithName("GetVenueStaff");

        staff.MapPost("/{id:guid}/approve", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new ReviewStaffCommand(id, Approve: true), cancellationToken)))
            .WithName("ApproveVenueStaff");

        staff.MapPost("/{id:guid}/reject", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new ReviewStaffCommand(id, Approve: false), cancellationToken)))
            .WithName("RejectVenueStaff");

        staff.MapDelete("/{id:guid}", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new RemoveStaffCommand(id), cancellationToken);
                return Results.NoContent();
            })
            .WithName("RemoveVenueStaff");

        return app;
    }
}
