using Hara.Domain.Reservations;

namespace Hara.Application.Reservations;

/// <summary>Read model for a <see cref="Reservation"/>, returned by every Reservations query/command.</summary>
/// <param name="Id">Unique identifier.</param>
/// <param name="RestaurantId">The restaurant the table is reserved at.</param>
/// <param name="RestaurantName">Display name of that restaurant.</param>
/// <param name="DiscountPercent">The restaurant's discount (0–100) the code entitles the customer to.</param>
/// <param name="PhoneNumber">The customer's phone number.</param>
/// <param name="Code">Short code the customer presents at the venue.</param>
/// <param name="DurationMinutes">How long the table is held for (30 for new reservations; older ones may be 60).</param>
/// <param name="CreatedAt">When the reservation was made.</param>
/// <param name="ExpiresAt">When the reservation window ends.</param>
/// <param name="Status">Effective state: pending, active, redeemed, cancelled, declined, or expired/unanswered once its deadline has passed.</param>
/// <param name="RedeemedAt">When staff redeemed the code, if they did.</param>
public sealed record ReservationDto(
    Guid Id,
    Guid RestaurantId,
    string RestaurantName,
    int DiscountPercent,
    string PhoneNumber,
    string Code,
    int DurationMinutes,
    DateTimeOffset CreatedAt,
    DateTimeOffset ExpiresAt,
    ReservationStatus Status,
    DateTimeOffset? RedeemedAt)
{
    /// <summary>Maps an entity whose <see cref="Reservation.Restaurant"/> has been loaded.</summary>
    public static ReservationDto FromEntity(Reservation reservation, DateTimeOffset now) => new(
        reservation.Id,
        reservation.RestaurantId,
        reservation.Restaurant!.Name,
        reservation.Restaurant.DiscountPercent,
        reservation.PhoneNumber,
        reservation.Code,
        reservation.DurationMinutes,
        reservation.CreatedAt,
        reservation.ExpiresAt,
        reservation.EffectiveStatus(now),
        reservation.RedeemedAt);
}
