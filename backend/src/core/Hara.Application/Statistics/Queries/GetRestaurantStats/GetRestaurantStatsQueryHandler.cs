using Hara.Application.Common.Interfaces;
using Hara.Domain.Reservations;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Statistics.Queries.GetRestaurantStats;

public class GetRestaurantStatsQueryHandler(IUnitOfWork unitOfWork)
    : IRequestHandler<GetRestaurantStatsQuery, IReadOnlyList<RestaurantStatsDto>>
{
    public async Task<IReadOnlyList<RestaurantStatsDto>> Handle(GetRestaurantStatsQuery request, CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        var startOfMonth = BakuTime.StartOfMonth(now);
        var startOfLastMonth = BakuTime.StartOfMonth(now, monthsBack: 1);

        var restaurants = await unitOfWork.Repository<Restaurant>().Query()
            .OrderBy(r => r.Name)
            .Select(r => new { r.Id, r.Name })
            .ToListAsync(cancellationToken);

        var thisMonth = await CountAsync(startOfMonth, null, now, cancellationToken);
        var lastMonth = await CountAsync(startOfLastMonth, startOfMonth, now, cancellationToken);
        var allTime = await CountAsync(null, null, now, cancellationToken);

        return restaurants
            .Select(r => new RestaurantStatsDto(
                r.Id,
                r.Name,
                thisMonth.GetValueOrDefault(r.Id, StatsPeriodDto.Empty),
                lastMonth.GetValueOrDefault(r.Id, StatsPeriodDto.Empty),
                allTime.GetValueOrDefault(r.Id, StatsPeriodDto.Empty)))
            .ToList();
    }

    /// <summary>Per restaurant, the requests sent from <paramref name="from"/> (inclusive) until <paramref name="to"/> (exclusive); no bound when <c>null</c>.</summary>
    private async Task<Dictionary<Guid, StatsPeriodDto>> CountAsync(DateTimeOffset? from, DateTimeOffset? to, DateTimeOffset now, CancellationToken cancellationToken)
    {
        var query = unitOfWork.Repository<Reservation>().Query().AsQueryable();
        if (from is not null)
        {
            query = query.Where(r => r.CreatedAt >= from);
        }

        if (to is not null)
        {
            query = query.Where(r => r.CreatedAt < to);
        }

        var rows = await query
            .GroupBy(r => r.RestaurantId)
            .Select(g => new
            {
                RestaurantId = g.Key,
                Requests = g.Count(),
                Accepted = g.Count(r => r.RespondedAt != null && r.Status != ReservationStatus.Declined),
                Declined = g.Count(r => r.Status == ReservationStatus.Declined),
                Unanswered = g.Count(r => r.Status == ReservationStatus.Pending && r.ExpiresAt <= now),
                Redeemed = g.Count(r => r.Status == ReservationStatus.Redeemed),
                NoShows = g.Count(r => r.Status == ReservationStatus.Active && r.ExpiresAt <= now)
            })
            .ToListAsync(cancellationToken);

        return rows.ToDictionary(
            r => r.RestaurantId,
            r => new StatsPeriodDto(r.Requests, r.Accepted, r.Declined, r.Unanswered, r.Redeemed, r.NoShows));
    }
}
