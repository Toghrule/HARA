namespace Hara.Domain.Reservations;

/// <summary>
/// Lifecycle state of a <see cref="Reservation"/>. The customer sends a request (<see cref="Pending"/>); the
/// restaurant's owner or a waiter accepts it (<see cref="Active"/>, and only then the hold timer starts) or
/// declines it (<see cref="Declined"/>). The numbers are part of the API (clients read them as integers), so new
/// states are only ever added at the end.
/// </summary>
public enum ReservationStatus
{
    /// <summary>Accepted by the restaurant and still usable: the code has not been redeemed and the hold time has not run out.</summary>
    Active = 0,

    /// <summary>The customer showed up and venue staff marked the code as used.</summary>
    Redeemed = 1,

    /// <summary>Cancelled by the customer before use.</summary>
    Cancelled = 2,

    /// <summary>
    /// The hold time ran out without the code being redeemed. This value is never stored: it is derived at read
    /// time from an <see cref="Active"/> reservation whose <see cref="Reservation.ExpiresAt"/> is in the past.
    /// </summary>
    Expired = 3,

    /// <summary>The customer's request is waiting for the restaurant to accept or decline it. The hold timer has not started.</summary>
    Pending = 4,

    /// <summary>The restaurant declined the request.</summary>
    Declined = 5,

    /// <summary>
    /// Nobody at the restaurant answered in time. Never stored: derived at read time from a <see cref="Pending"/>
    /// request whose <see cref="Reservation.ExpiresAt"/> (the answer deadline) is in the past.
    /// </summary>
    Unanswered = 6
}
