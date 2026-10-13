using Hara.Domain.Common;
using Hara.Domain.Restaurants;

namespace Hara.Domain.Reservations;

/// <summary>
/// A table request made anonymously from the mobile app with just a phone number. The restaurant's owner or a
/// waiter has to accept it; only then does the hold timer start and the customer see the <see cref="Code"/> to
/// show at the venue to claim the restaurant's discount.
/// </summary>
public class Reservation : BaseAuditableEntity
{
    /// <summary>How long a reservation holds the table once the restaurant accepts it, in minutes.</summary>
    public const int HoldMinutes = 30;

    /// <summary>How long the restaurant has to answer a request before it counts as unanswered, in minutes.</summary>
    public const int AnswerWithinMinutes = 15;

    /// <summary>The restaurant the table is reserved at.</summary>
    public Guid RestaurantId { get; set; }

    /// <summary>The reserved restaurant.</summary>
    public Restaurant? Restaurant { get; set; }

    /// <summary>Phone number the customer left so the venue can reach them.</summary>
    public string PhoneNumber { get; set; } = string.Empty;

    /// <summary>How long the table is held for once accepted, in minutes. Reservations made before the limit was set to <see cref="HoldMinutes"/> may have held it for 60.</summary>
    public int DurationMinutes { get; set; }

    /// <summary>Short, unique, human-friendly code the customer presents at the venue.</summary>
    public string Code { get; set; } = string.Empty;

    /// <summary>
    /// The deadline that currently applies. While the request is <see cref="ReservationStatus.Pending"/> it is the
    /// time by which the restaurant must answer; once the restaurant accepts it, it is the end of the hold time
    /// (accepted time + <see cref="DurationMinutes"/>), after which the code can no longer be redeemed.
    /// </summary>
    public DateTimeOffset ExpiresAt { get; set; }

    /// <summary>Stored state. Never <see cref="ReservationStatus.Expired"/> or <see cref="ReservationStatus.Unanswered"/>; see <see cref="EffectiveStatus"/>.</summary>
    public ReservationStatus Status { get; set; } = ReservationStatus.Pending;

    /// <summary>When the restaurant accepted or declined the request, or <c>null</c> while it has not answered.</summary>
    public DateTimeOffset? RespondedAt { get; set; }

    /// <summary>The owner or waiter who accepted or declined the request.</summary>
    public Guid? RespondedByUserId { get; set; }

    /// <summary>When venue staff redeemed the code, or <c>null</c> if not redeemed.</summary>
    public DateTimeOffset? RedeemedAt { get; set; }

    /// <summary>The owner or waiter who confirmed the code at the venue, so the restaurant can see who did.</summary>
    public Guid? RedeemedByUserId { get; set; }

    /// <summary>
    /// The state to show users: the stored <see cref="Status"/>, except that a request nobody answered before its
    /// deadline is <see cref="ReservationStatus.Unanswered"/> and an accepted reservation past its hold time is
    /// <see cref="ReservationStatus.Expired"/>.
    /// </summary>
    public ReservationStatus EffectiveStatus(DateTimeOffset now) => Status switch
    {
        ReservationStatus.Active when ExpiresAt <= now => ReservationStatus.Expired,
        ReservationStatus.Pending when ExpiresAt <= now => ReservationStatus.Unanswered,
        _ => Status
    };

    /// <summary>Whether the customer still has this reservation going: waiting for an answer, or accepted and not yet over.</summary>
    public bool IsInProgress(DateTimeOffset now) => EffectiveStatus(now) is ReservationStatus.Pending or ReservationStatus.Active;
}
