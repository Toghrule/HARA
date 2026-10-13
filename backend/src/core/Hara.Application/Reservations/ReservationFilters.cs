using Hara.Domain.Reservations;

namespace Hara.Application.Reservations;

public static class ReservationFilters
{
    /// <summary>
    /// Keeps the reservations whose <em>effective</em> state is <paramref name="status"/> (all of them when <c>null</c>).
    /// "Expired" and "Unanswered" are not stored: they are an accepted reservation, or an unanswered request, whose
    /// deadline has passed, so the clock decides which row is which.
    /// </summary>
    public static IQueryable<Reservation> WithEffectiveStatus(this IQueryable<Reservation> query, ReservationStatus? status, DateTimeOffset now) =>
        status switch
        {
            ReservationStatus.Active => query.Where(r => r.Status == ReservationStatus.Active && r.ExpiresAt > now),
            ReservationStatus.Expired => query.Where(r => r.Status == ReservationStatus.Active && r.ExpiresAt <= now),
            ReservationStatus.Pending => query.Where(r => r.Status == ReservationStatus.Pending && r.ExpiresAt > now),
            ReservationStatus.Unanswered => query.Where(r => r.Status == ReservationStatus.Pending && r.ExpiresAt <= now),
            ReservationStatus.Redeemed => query.Where(r => r.Status == ReservationStatus.Redeemed),
            ReservationStatus.Cancelled => query.Where(r => r.Status == ReservationStatus.Cancelled),
            ReservationStatus.Declined => query.Where(r => r.Status == ReservationStatus.Declined),
            _ => query
        };
}
