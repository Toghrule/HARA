using MediatR;

namespace Hara.Application.Reservations.Commands.CreateReservation;

/// <summary>Public command: a customer reserves a table with just a phone number. Free, no account.</summary>
/// <param name="RestaurantId">The (active) restaurant to reserve at.</param>
/// <param name="PhoneNumber">The customer's phone number.</param>
/// <param name="DurationMinutes">How long to hold the table. Only 30 is accepted (kept in the request so older clients keep working).</param>
public sealed record CreateReservationCommand(
    Guid RestaurantId,
    string PhoneNumber,
    int DurationMinutes) : IRequest<ReservationDto>;
