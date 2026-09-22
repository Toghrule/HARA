namespace Hara.Application.Restaurants.Queries.GetRestaurants;

/// <summary>How to order a restaurant listing.</summary>
public enum RestaurantSortBy
{
    /// <summary>Alphabetical, A → Z (the default).</summary>
    NameAsc,

    /// <summary>Alphabetical, Z → A.</summary>
    NameDesc,

    /// <summary>
    /// Closest first, measured from a given point. Requires <see cref="GetRestaurantsQuery.Latitude"/>
    /// and <see cref="GetRestaurantsQuery.Longitude"/>; falls back to <see cref="NameAsc"/> if either is missing.
    /// </summary>
    Nearest,
}
