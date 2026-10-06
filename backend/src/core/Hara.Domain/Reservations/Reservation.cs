using Hara.Domain.Common;
using Hara.Domain.Restaurants;

namespace Hara.Domain.Reservations;

/// <summary>
/// A free table reservation made anonymously from the mobile app with just a phone number.
/// The customer receives a short <see cref="Code"/>, must arrive before <see cref="ExpiresAt"/>,
/// and shows the code at the venue to claim the restaurant's discount.
/// </summary>
public class Reservation : BaseAuditableEntity
{
    /// <summary>The restaurant the table is reserved at.</summary>
    public Guid RestaurantId { get; set; }

    /// <summary>The reserved restaurant.</summary>
    public Restaurant? Restaurant { get; set; }

    /// <summary>Phone number the customer left so the venue can reach them.</summary>
    public string PhoneNumber { get; set; } = string.Empty;

    /// <summary>How long the table is held for, in minutes (30 or 60).</summary>
    public int DurationMinutes { get; set; }

    /// <summary>Short, unique, human-friendly code the customer presents at the venue.</summary>
    public string Code { get; set; } = string.Empty;

    /// <summary>When the reservation window ends. After this the code can no longer be redeemed.</summary>
    public DateTimeOffset ExpiresAt { get; set; }

    /// <summary>Stored state. Never <see cref="ReservationStatus.Expired"/>; see <see cref="IsExpired"/>.</summary>
    public ReservationStatus Status { get; set; } = ReservationStatus.Active;

    /// <summary>When venue staff redeemed the code, or <c>null</c> if not redeemed.</summary>
    public DateTimeOffset? RedeemedAt { get; set; }

    /// <summary>Whether the reservation is still active but its window has already elapsed at <paramref name="now"/>.</summary>
    public bool IsExpired(DateTimeOffset now) => Status == ReservationStatus.Active && ExpiresAt <= now;

    /// <summary>The state to show users: the stored <see cref="Status"/>, or <see cref="ReservationStatus.Expired"/> when the window has elapsed.</summary>
    public ReservationStatus EffectiveStatus(DateTimeOffset now) => IsExpired(now) ? ReservationStatus.Expired : Status;
}
