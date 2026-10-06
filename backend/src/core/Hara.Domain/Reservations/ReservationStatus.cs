namespace Hara.Domain.Reservations;

/// <summary>Lifecycle state of a <see cref="Reservation"/>.</summary>
public enum ReservationStatus
{
    /// <summary>Created and still usable: the code has not been redeemed and the reservation window has not elapsed.</summary>
    Active = 0,

    /// <summary>The customer showed up and venue staff marked the code as used.</summary>
    Redeemed = 1,

    /// <summary>Cancelled before use.</summary>
    Cancelled = 2,

    /// <summary>
    /// The reservation window elapsed without the code being redeemed. This value is
    /// never stored: it is derived at read time from an <see cref="Active"/> reservation
    /// whose <see cref="Reservation.ExpiresAt"/> is in the past.
    /// </summary>
    Expired = 3
}
