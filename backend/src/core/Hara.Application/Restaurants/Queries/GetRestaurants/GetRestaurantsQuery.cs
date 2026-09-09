using MediatR;

namespace Hara.Application.Restaurants.Queries.GetRestaurants;

/// <summary>
/// Lists restaurants. The public endpoint always passes <paramref name="OnlyActive"/>
/// = <c>true</c>; the admin endpoint passes <c>false</c> to see everything, including
/// deactivated restaurants.
/// </summary>
public sealed record GetRestaurantsQuery(bool OnlyActive) : IRequest<IReadOnlyList<RestaurantDto>>;
