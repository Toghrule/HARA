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
/// <param name="Search">Only restaurants whose name or address contains this text (ignoring case and Azerbaijani diacritics).</param>
/// <param name="PageSize">When set, returns just one page of this many restaurants; when null, returns them all.</param>
/// <param name="Page">1-based page to return when <paramref name="PageSize"/> is set. Defaults to the first page.</param>
public sealed record GetRestaurantsQuery(
    bool OnlyActive,
    RestaurantSortBy SortBy = RestaurantSortBy.NameAsc,
    double? Latitude = null,
    double? Longitude = null,
    string? Search = null,
    int? PageSize = null,
    int? Page = null,
    string? Language = null) : IRequest<IReadOnlyList<RestaurantDto>>;
