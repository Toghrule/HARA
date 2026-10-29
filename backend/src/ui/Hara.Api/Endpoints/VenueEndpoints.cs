using Hara.Application.ChangeRequests.Commands.CreateChangeRequest;
using Hara.Application.ChangeRequests.Queries.GetVenueChangeRequests;
using Hara.Application.Devices;
using Hara.Application.Venue.Commands.RedeemVenueReservation;
using Hara.Application.Venue.Commands.RemoveStaff;
using Hara.Application.Venue.Commands.RespondToReservation;
using Hara.Application.Venue.Commands.ReviewStaff;
using Hara.Application.Venue.Commands.UpdateOpeningHours;
using Hara.Application.Venue.Queries.GetMyVenueStatus;
using Hara.Application.Venue.Queries.GetVenueReservation;
using Hara.Application.Venue.Queries.GetVenueReservations;
using Hara.Application.Venue.Queries.GetVenueStaff;
using Hara.Application.Venue.Queries.GetVenueStats;
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

        // This phone wants to hear about new requests while this person is signed in on it.
        venue.MapGet("/stats", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetVenueStatsQuery(), cancellationToken)))
            .WithName("GetVenueStats");

        venue.MapPost("/devices", async (DeviceBody body, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new RegisterVenueDeviceCommand(body.Token, body.Language), cancellationToken);
                return Results.NoContent();
            })
            .WithName("RegisterVenueDevice");

        venue.MapPost("/devices/unregister", async (DeviceBody body, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new UnregisterVenueDeviceCommand(body.Token), cancellationToken);
                return Results.NoContent();
            })
            .WithName("UnregisterVenueDevice");

        venue.MapGet("/reservations", async (ReservationStatus? status, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetVenueReservationsQuery(status), cancellationToken)))
            .WithName("GetVenueReservations");

        venue.MapGet("/reservations/{code}", async (string code, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetVenueReservationQuery(code), cancellationToken)))
            .WithName("GetVenueReservation");

        venue.MapPost("/reservations/{code}/accept", async (string code, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new RespondToReservationCommand(code, Accept: true), cancellationToken)))
            .WithName("AcceptVenueReservation");

        venue.MapPost("/reservations/{code}/decline", async (string code, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new RespondToReservationCommand(code, Accept: false), cancellationToken)))
            .WithName("DeclineVenueReservation");

        venue.MapPost("/reservations/{code}/redeem", async (string code, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new RedeemVenueReservationCommand(code), cancellationToken)))
            .WithName("RedeemVenueReservation");

        // Owner only: when the restaurant is open. Applies at once, unlike changes to the name or address.
        venue.MapPut("/opening-hours", async (UpdateOpeningHoursCommand command, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(command, cancellationToken)))
            .RequireAuthorization("Owner")
            .WithName("UpdateOpeningHours");

        var requests = venue.MapGroup("/change-requests").RequireAuthorization("Owner");

        requests.MapGet("/", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetVenueChangeRequestsQuery(), cancellationToken)))
            .WithName("GetVenueChangeRequests");

        requests.MapPost("/", async (CreateChangeRequestCommand command, ISender sender, CancellationToken cancellationToken) =>
                Results.Created((string?)null, await sender.Send(command, cancellationToken)))
            .WithName("CreateVenueChangeRequest");

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
