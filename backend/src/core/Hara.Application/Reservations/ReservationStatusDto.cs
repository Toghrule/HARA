using Hara.Domain.Reservations;

namespace Hara.Application.Reservations;

/// <summary>
/// What the public status check tells whoever holds a reservation code. Deliberately minimal — no phone
/// number or restaurant — so a guessed code reveals nothing about the customer.
/// </summary>
/// <param name="Code">The reservation code that was asked about.</param>
/// <param name="Status">Effective state — <see cref="ReservationStatus.Expired"/> once an active reservation's window has elapsed.</param>
/// <param name="ExpiresAt">When the reservation window ends.</param>
/// <param name="RedeemedAt">When staff redeemed the code, if they did.</param>
public sealed record ReservationStatusDto(
    string Code,
    ReservationStatus Status,
    DateTimeOffset ExpiresAt,
    DateTimeOffset? RedeemedAt)
{
    public static ReservationStatusDto FromEntity(Reservation reservation, DateTimeOffset now) => new(
        reservation.Code,
        reservation.EffectiveStatus(now),
        reservation.ExpiresAt,
        reservation.RedeemedAt);
}
