using Hara.Api.RateLimiting;
using Hara.Application.Devices;
using Hara.Application.Reservations.Commands.CancelReservation;
using Hara.Application.Reservations.Commands.CreateReservation;
using Hara.Application.Reservations.Queries.GetReservations;
using Hara.Application.Reservations.Queries.GetReservationStatus;
using Hara.Application.Statistics.Queries.GetRestaurantStats;
using Hara.Domain.Reservations;
using MediatR;

namespace Hara.Api.Endpoints;

/// <summary>A phone's Firebase notification token and the language to write its notifications in.</summary>
public sealed record DeviceBody(string Token, string? Language);

public static class ReservationsEndpoints
{
    public static IEndpointRouteBuilder MapReservationsEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/reservations", async (CreateReservationCommand command, ISender sender, CancellationToken cancellationToken) =>
            {
                var result = await sender.Send(command, cancellationToken);
                return Results.Created((string?)null, result);
            })
            .WithTags("Reservations")
            .WithName("CreateReservation")
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.Reservations);

        app.MapGet("/api/reservations/{code}/status", async (string code, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetReservationStatusQuery(code), cancellationToken)))
            .WithTags("Reservations")
            .WithName("GetReservationStatus")
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.ReservationStatusChecks);

        app.MapPost("/api/reservations/{code}/cancel", async (string code, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new CancelReservationCommand(code), cancellationToken)))
            .WithTags("Reservations")
            .WithName("CancelReservation")
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.ReservationCancels);

        // The phone that sent the request asks to be notified of the restaurant's answer. The code is the proof of ownership.
        app.MapPost("/api/reservations/{code}/device", async (string code, DeviceBody body, ISender sender, CancellationToken cancellationToken) =>
            {
                await sender.Send(new RegisterReservationDeviceCommand(code, body.Token, body.Language), cancellationToken);
                return Results.NoContent();
            })
            .WithTags("Reservations")
            .WithName("RegisterReservationDevice")
            .AllowAnonymous()
            .RequireRateLimiting(RateLimitPolicies.Devices);

        var admin = app.MapGroup("/api/admin/reservations")
            .WithTags("Admin.Reservations")
            .RequireAuthorization("Admin");

        admin.MapGet("/", async (string? code, ReservationStatus? status, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetReservationsQuery(code, status), cancellationToken)))
            .WithName("AdminGetReservations");

        // What the admin shows restaurants to prove the app is worth it: per restaurant, this month, last month and all time.
        app.MapGet("/api/admin/stats/restaurants", async (ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetRestaurantStatsQuery(), cancellationToken)))
            .WithTags("Admin.Reservations")
            .RequireAuthorization("Admin")
            .WithName("AdminGetRestaurantStats");

        // Confirming a code is done by the restaurant's own owner or waiter (see VenueEndpoints), not by the admin.

        return app;
    }
}
