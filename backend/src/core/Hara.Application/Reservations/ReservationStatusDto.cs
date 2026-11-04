using Hara.Domain.Reservations;

namespace Hara.Application.Reservations;

/// <summary>
/// What the public status check tells whoever holds a reservation code. Deliberately minimal — no phone
/// number or restaurant — so a guessed code reveals nothing about the customer.
/// </summary>
/// <param name="Code">The reservation code that was asked about.</param>
/// <param name="Status">Effective state: pending, active, redeemed, cancelled, declined, or expired/unanswered once its deadline has passed.</param>
/// <param name="ExpiresAt">When the reservation window ends.</param>
/// <param name="RedeemedAt">When staff redeemed the code, if they did.</param>
/// <param name="Rating">The stars this phone number already gave the restaurant, or <c>null</c> if it has not rated.</param>
public sealed record ReservationStatusDto(
    string Code,
    ReservationStatus Status,
    DateTimeOffset ExpiresAt,
    DateTimeOffset? RedeemedAt,
    int? Rating = null)
{
    public static ReservationStatusDto FromEntity(Reservation reservation, DateTimeOffset now, int? rating = null) => new(
        reservation.Code,
        reservation.EffectiveStatus(now),
        reservation.ExpiresAt,
        reservation.RedeemedAt,
        rating);
}
