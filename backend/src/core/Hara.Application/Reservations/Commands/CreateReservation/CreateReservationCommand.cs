using MediatR;

namespace Hara.Application.Reservations.Commands.CreateReservation;

/// <summary>Public command: a customer reserves a table with just a phone number. Free, no account.</summary>
/// <param name="RestaurantId">The (active) restaurant to reserve at.</param>
/// <param name="PhoneNumber">The customer's phone number.</param>
/// <param name="DurationMinutes">How long to hold the table: 30 or 60.</param>
public sealed record CreateReservationCommand(
    Guid RestaurantId,
    string PhoneNumber,
    int DurationMinutes) : IRequest<ReservationDto>;
