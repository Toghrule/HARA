using Hara.Domain.Discounts;
using Hara.Domain.Reservations;

namespace Hara.Application.Discounts;

/// <summary>
/// A discount code as the customer's app sees it. <paramref name="Status"/> uses the numbers of <see cref="ReservationStatus"/>
/// (active 0, redeemed 1, expired 3) so the app reads it the way it reads a reservation.
/// </summary>
public sealed record DiscountCodeDto(
    string Code,
    Guid RestaurantId,
    string RestaurantName,
    int DiscountPercent,
    DateTimeOffset CreatedAt,
    DateTimeOffset ExpiresAt,
    ReservationStatus Status,
    DateTimeOffset? RedeemedAt)
{
    public static DiscountCodeDto From(DiscountCode code, string restaurantName, DateTimeOffset now) => new(
        code.Code,
        code.RestaurantId,
        restaurantName,
        code.DiscountPercent,
        code.CreatedAt,
        code.ExpiresAt,
        StatusOf(code, now),
        code.RedeemedAt);

    public static ReservationStatus StatusOf(DiscountCode code, DateTimeOffset now) =>
        code.RedeemedAt is not null ? ReservationStatus.Redeemed : code.ExpiresAt <= now ? ReservationStatus.Expired : ReservationStatus.Active;
}
