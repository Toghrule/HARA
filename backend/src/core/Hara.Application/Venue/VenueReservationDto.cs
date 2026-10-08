using Hara.Domain.Reservations;

namespace Hara.Application.Venue;

/// <summary>
/// A customer's reservation as the restaurant sees it when confirming a code. The phone number is here
/// because the venue may need to reach the customer.
/// </summary>
/// <param name="Id">Unique identifier.</param>
/// <param name="Code">The code the customer shows.</param>
/// <param name="PhoneNumber">The customer's phone number.</param>
/// <param name="DurationMinutes">How long the table is held for (30 or 60).</param>
/// <param name="CreatedAt">When the customer reserved.</param>
/// <param name="ExpiresAt">When the reservation window ends.</param>
/// <param name="Status">Effective state — <see cref="ReservationStatus.Expired"/> once an active reservation's window has elapsed.</param>
/// <param name="RedeemedAt">When the code was confirmed, if it was.</param>
/// <param name="DiscountPercent">The restaurant's discount (0–100) the customer is entitled to.</param>
public sealed record VenueReservationDto(
    Guid Id,
    string Code,
    string PhoneNumber,
    int DurationMinutes,
    DateTimeOffset CreatedAt,
    DateTimeOffset ExpiresAt,
    ReservationStatus Status,
    DateTimeOffset? RedeemedAt,
    int DiscountPercent)
{
    public static VenueReservationDto FromEntity(Reservation reservation, int discountPercent, DateTimeOffset now) => new(
        reservation.Id,
        reservation.Code,
        reservation.PhoneNumber,
        reservation.DurationMinutes,
        reservation.CreatedAt,
        reservation.ExpiresAt,
        reservation.EffectiveStatus(now),
        reservation.RedeemedAt,
        discountPercent);
}
