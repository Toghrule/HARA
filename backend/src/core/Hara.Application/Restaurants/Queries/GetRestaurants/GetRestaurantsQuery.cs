using MediatR;

namespace Hara.Application.Restaurants.Queries.GetRestaurants;

/// <summary>
/// Lists restaurants. The public endpoint always passes <paramref name="OnlyActive"/>
/// = <c>true</c>; the admin endpoint passes <c>false</c> to see everything, including
/// deactivated restaurants.
/// </summary>
/// <param name="OnlyActive">When true, excludes deactivated restaurants.</param>
/// <param name="SortBy">How to order the results. Defaults to alphabetical (A → Z).</param>
/// <param name="Latitude">Caller's latitude, required for <see cref="RestaurantSortBy.Nearest"/>.</param>
/// <param name="Longitude">Caller's longitude, required for <see cref="RestaurantSortBy.Nearest"/>.</param>
public sealed record GetRestaurantsQuery(
    bool OnlyActive,
    RestaurantSortBy SortBy = RestaurantSortBy.NameAsc,
    double? Latitude = null,
    double? Longitude = null) : IRequest<IReadOnlyList<RestaurantDto>>;
