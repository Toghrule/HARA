using Hara.Application.Common;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Restaurants.Queries.GetRestaurants;

public class GetRestaurantsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetRestaurantsQuery, IReadOnlyList<RestaurantDto>>
{
    private const double EarthRadiusKm = 6371.0;

    public async Task<IReadOnlyList<RestaurantDto>> Handle(GetRestaurantsQuery request, CancellationToken cancellationToken)
    {
        var query = unitOfWork.Repository<Restaurant>().Query();

        if (request.OnlyActive)
        {
            query = query.Where(r => r.IsActive);
        }

        var restaurants = await query.ToListAsync(cancellationToken);

        // Filtered in memory, like the sorting below, so matching can ignore Azerbaijani diacritics
        // consistently instead of depending on the database's collation.
        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            var term = SearchText.Fold(request.Search);
            restaurants = restaurants
                .Where(r => SearchText.Fold(r.Name).Contains(term) || SearchText.Fold(r.Address).Contains(term))
                .ToList();
        }

        var sortBy = request.SortBy == RestaurantSortBy.Nearest && (request.Latitude is null || request.Longitude is null)
            ? RestaurantSortBy.NameAsc
            : request.SortBy;

        IEnumerable<Restaurant> sorted = sortBy switch
        {
            RestaurantSortBy.NameDesc => restaurants.OrderByDescending(r => r.Name, StringComparer.OrdinalIgnoreCase),
            RestaurantSortBy.Nearest => restaurants.OrderBy(r => DistanceKm(request.Latitude!.Value, request.Longitude!.Value, r.Latitude, r.Longitude)),
            _ => restaurants.OrderBy(r => r.Name, StringComparer.OrdinalIgnoreCase),
        };

        if (request.PageSize is { } pageSize)
        {
            sorted = sorted.Skip(((request.Page ?? 1) - 1) * pageSize).Take(pageSize);
        }

        return sorted.Select(RestaurantDto.FromEntity).ToList();
    }

    /// <summary>Great-circle distance between two points, in kilometers (Haversine formula).</summary>
    private static double DistanceKm(double lat1, double lon1, double lat2, double lon2)
    {
        var dLat = DegreesToRadians(lat2 - lat1);
        var dLon = DegreesToRadians(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(DegreesToRadians(lat1)) * Math.Cos(DegreesToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return EarthRadiusKm * c;
    }

    private static double DegreesToRadians(double degrees) => degrees * Math.PI / 180.0;
}
