using Hara.Domain.Common;
using Hara.Domain.Reservations;

namespace Hara.Domain.Devices;

/// <summary>
/// A phone that asked to be notified through Firebase Cloud Messaging. A row belongs either to a restaurant
/// account (<see cref="UserId"/>: told about new requests) or to one customer reservation
/// (<see cref="ReservationId"/>: told the restaurant's answer). The same phone can have one row of each kind.
/// </summary>
public class DeviceToken : BaseAuditableEntity
{
    /// <summary>The FCM registration token Firebase gave the app on this phone.</summary>
    public string Token { get; set; } = string.Empty;

    /// <summary>"az", "ru" or "en": which language the notification text is written in.</summary>
    public string Language { get; set; } = "az";

    /// <summary>The restaurant account signed in on the phone, for a restaurant-side token.</summary>
    public Guid? UserId { get; set; }

    /// <summary>The customer's reservation, for a customer-side token.</summary>
    public Guid? ReservationId { get; set; }

    public Reservation? Reservation { get; set; }
}
