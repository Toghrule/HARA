using Hara.Application.Common.Interfaces;
using Hara.Application.Statistics;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Restaurants.Queries.GetFeaturedRestaurants;

/// <summary>
/// The restaurants that are this week's picks today (Azerbaijan time), for the top of the app. Independent of where the customer is and
/// of any filter. Only active restaurants; the ones whose turn began earliest come first, then by name.
/// </summary>
/// <param name="Language">The language of the description (az, ru, en); Azerbaijani when empty.</param>
public sealed record GetFeaturedRestaurantsQuery(string? Language = null) : IRequest<IReadOnlyList<RestaurantDto>>;

public class GetFeaturedRestaurantsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetFeaturedRestaurantsQuery, IReadOnlyList<RestaurantDto>>
{
    /// <summary>More than this many at once would stop being a short list to look at.</summary>
    private const int MaxPicks = 12;

    public async Task<IReadOnlyList<RestaurantDto>> Handle(GetFeaturedRestaurantsQuery request, CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        var today = BakuTime.DayOf(now);

        var picks = await unitOfWork.Repository<Restaurant>().Query()
            .Where(r => r.IsActive && r.FeaturedFrom != null && r.FeaturedUntil != null && r.FeaturedFrom <= today && r.FeaturedUntil >= today)
            .OrderBy(r => r.FeaturedFrom)
            .ThenBy(r => r.Name)
            .Take(MaxPicks)
            .ToListAsync(cancellationToken);

        return picks
            .Select(r => request.Language is null ? RestaurantDto.FromEntity(r, now) : RestaurantDto.FromEntity(r, now).Localize(request.Language))
            .ToList();
    }
}
