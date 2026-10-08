using Hara.Application.Venue.Commands.RedeemVenueReservation;
using Hara.Application.Venue.Commands.RemoveStaff;
using Hara.Application.Venue.Commands.ReviewStaff;
using Hara.Application.Venue.Queries.GetMyVenueStatus;
using Hara.Application.Venue.Queries.GetVenueReservation;
using Hara.Application.Venue.Queries.GetVenueReservations;
using Hara.Application.Venue.Queries.GetVenueStaff;
using Hara.Domain.Reservations;
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

        venue.MapGet("/reservations", async (ReservationStatus? status, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetVenueReservationsQuery(status), cancellationToken)))
            .WithName("GetVenueReservations");

        venue.MapGet("/reservations/{code}", async (string code, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetVenueReservationQuery(code), cancellationToken)))
            .WithName("GetVenueReservation");

        venue.MapPost("/reservations/{code}/redeem", async (string code, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new RedeemVenueReservationCommand(code), cancellationToken)))
            .WithName("RedeemVenueReservation");

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
