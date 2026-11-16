using Hara.Application.Common.Interfaces;
using Hara.Application.Statistics;
using Hara.Domain.Discounts;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Discounts;

/// <summary>What happened at one restaurant in a period: codes customers got, codes the restaurant confirmed (the customers HARA brought), and taps on the restaurant and on the way to it.</summary>
public sealed record VisitCountsDto(int CodesObtained, int CodesRedeemed, int Views, int Directions);

public sealed record RestaurantVisitsDto(Guid RestaurantId, string Name, int DiscountPercent, VisitCountsDto Today, VisitCountsDto ThisWeek, VisitCountsDto ThisMonth, VisitCountsDto Total);

/// <summary>Admin: for every restaurant, today, this week (from Monday), this month and all time.</summary>
public sealed record GetVisitsQuery : IRequest<IReadOnlyList<RestaurantVisitsDto>>;

/// <summary>Admin: one month for every restaurant (the monthly result to send the owner), as <c>year</c> and <c>month</c> (1-12).</summary>
public sealed record GetMonthlyVisitsQuery(int Year, int Month) : IRequest<IReadOnlyList<MonthlyVisitsDto>>;

/// <param name="UniqueViewers">Different devices that opened the restaurant's page during the month.</param>
public sealed record MonthlyVisitsDto(Guid RestaurantId, string Name, int DiscountPercent, VisitCountsDto Counts, int UniqueViewers);

public class GetVisitsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetVisitsQuery, IReadOnlyList<RestaurantVisitsDto>>
{
    public async Task<IReadOnlyList<RestaurantVisitsDto>> Handle(GetVisitsQuery request, CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        var day = BakuTime.StartOfDay(now);
        var week = BakuTime.StartOfWeek(now);
        var month = BakuTime.StartOfMonth(now);

        var restaurants = await unitOfWork.Repository<Restaurant>().Query().OrderBy(r => r.Name).Select(r => new { r.Id, r.Name, r.DiscountPercent }).ToListAsync(cancellationToken);

        var codes = await unitOfWork.Repository<DiscountCode>().Query()
            .GroupBy(c => c.RestaurantId)
            .Select(g => new
            {
                Id = g.Key,
                ObtainedDay = g.Count(c => c.CreatedAt >= day), ObtainedWeek = g.Count(c => c.CreatedAt >= week), ObtainedMonth = g.Count(c => c.CreatedAt >= month), ObtainedTotal = g.Count(),
                RedeemedDay = g.Count(c => c.RedeemedAt >= day), RedeemedWeek = g.Count(c => c.RedeemedAt >= week), RedeemedMonth = g.Count(c => c.RedeemedAt >= month), RedeemedTotal = g.Count(c => c.RedeemedAt != null),
            })
            .ToListAsync(cancellationToken);

        var events = await unitOfWork.Repository<RestaurantEvent>().Query()
            .GroupBy(e => e.RestaurantId)
            .Select(g => new
            {
                Id = g.Key,
                ViewsDay = g.Count(e => e.Type == RestaurantEvent.View && e.CreatedAt >= day), ViewsWeek = g.Count(e => e.Type == RestaurantEvent.View && e.CreatedAt >= week),
                ViewsMonth = g.Count(e => e.Type == RestaurantEvent.View && e.CreatedAt >= month), ViewsTotal = g.Count(e => e.Type == RestaurantEvent.View),
                DirDay = g.Count(e => e.Type == RestaurantEvent.Directions && e.CreatedAt >= day), DirWeek = g.Count(e => e.Type == RestaurantEvent.Directions && e.CreatedAt >= week),
                DirMonth = g.Count(e => e.Type == RestaurantEvent.Directions && e.CreatedAt >= month), DirTotal = g.Count(e => e.Type == RestaurantEvent.Directions),
            })
            .ToListAsync(cancellationToken);

        return restaurants.Select(r =>
        {
            var c = codes.FirstOrDefault(x => x.Id == r.Id);
            var e = events.FirstOrDefault(x => x.Id == r.Id);

            return new RestaurantVisitsDto(
                r.Id,
                r.Name,
                r.DiscountPercent,
                new VisitCountsDto(c?.ObtainedDay ?? 0, c?.RedeemedDay ?? 0, e?.ViewsDay ?? 0, e?.DirDay ?? 0),
                new VisitCountsDto(c?.ObtainedWeek ?? 0, c?.RedeemedWeek ?? 0, e?.ViewsWeek ?? 0, e?.DirWeek ?? 0),
                new VisitCountsDto(c?.ObtainedMonth ?? 0, c?.RedeemedMonth ?? 0, e?.ViewsMonth ?? 0, e?.DirMonth ?? 0),
                new VisitCountsDto(c?.ObtainedTotal ?? 0, c?.RedeemedTotal ?? 0, e?.ViewsTotal ?? 0, e?.DirTotal ?? 0));
        }).ToList();
    }
}

public class GetMonthlyVisitsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetMonthlyVisitsQuery, IReadOnlyList<MonthlyVisitsDto>>
{
    public async Task<IReadOnlyList<MonthlyVisitsDto>> Handle(GetMonthlyVisitsQuery request, CancellationToken cancellationToken)
    {
        var from = BakuTime.StartOfMonth(request.Year, request.Month);
        var to = from.AddMonths(1);

        var restaurants = await unitOfWork.Repository<Restaurant>().Query().OrderBy(r => r.Name).Select(r => new { r.Id, r.Name, r.DiscountPercent }).ToListAsync(cancellationToken);

        var codes = await unitOfWork.Repository<DiscountCode>().Query()
            .GroupBy(c => c.RestaurantId)
            .Select(g => new
            {
                Id = g.Key,
                Obtained = g.Count(c => c.CreatedAt >= from && c.CreatedAt < to),
                Redeemed = g.Count(c => c.RedeemedAt >= from && c.RedeemedAt < to),
            })
            .ToListAsync(cancellationToken);

        var events = await unitOfWork.Repository<RestaurantEvent>().Query()
            .Where(e => e.CreatedAt >= from && e.CreatedAt < to)
            .GroupBy(e => e.RestaurantId)
            .Select(g => new
            {
                Id = g.Key,
                Views = g.Count(e => e.Type == RestaurantEvent.View),
                Directions = g.Count(e => e.Type == RestaurantEvent.Directions),
                Unique = g.Where(e => e.Type == RestaurantEvent.View).Select(e => e.DeviceId).Distinct().Count(),
            })
            .ToListAsync(cancellationToken);

        return restaurants.Select(r =>
        {
            var c = codes.FirstOrDefault(x => x.Id == r.Id);
            var e = events.FirstOrDefault(x => x.Id == r.Id);

            return new MonthlyVisitsDto(r.Id, r.Name, r.DiscountPercent, new VisitCountsDto(c?.Obtained ?? 0, c?.Redeemed ?? 0, e?.Views ?? 0, e?.Directions ?? 0), e?.Unique ?? 0);
        }).ToList();
    }
}
