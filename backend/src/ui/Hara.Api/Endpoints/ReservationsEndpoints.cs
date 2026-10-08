using Hara.Api.RateLimiting;
using Hara.Application.Reservations.Commands.CancelReservation;
using Hara.Application.Reservations.Commands.CreateReservation;
using Hara.Application.Reservations.Commands.RedeemReservation;
using Hara.Application.Reservations.Queries.GetReservations;
using Hara.Application.Reservations.Queries.GetReservationStatus;
using Hara.Domain.Reservations;
using MediatR;

namespace Hara.Api.Endpoints;

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

        var admin = app.MapGroup("/api/admin/reservations")
            .WithTags("Admin.Reservations")
            .RequireAuthorization("Admin");

        admin.MapGet("/", async (string? code, ReservationStatus? status, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new GetReservationsQuery(code, status), cancellationToken)))
            .WithName("AdminGetReservations");

        admin.MapPatch("/{id:guid}/redeem", async (Guid id, ISender sender, CancellationToken cancellationToken) =>
                Results.Ok(await sender.Send(new RedeemReservationCommand(id), cancellationToken)))
            .WithName("AdminRedeemReservation");

        return app;
    }
}
