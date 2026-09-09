using MediatR;

namespace Hara.Application.Restaurants.Queries.GetRestaurantById;

/// <summary>
/// Fetches a single restaurant. The public endpoint passes <paramref name="OnlyActive"/>
/// = <c>true</c> so an inactive restaurant 404s for mobile app users the same as a
/// nonexistent one; the admin endpoint passes <c>false</c>.
/// </summary>
public sealed record GetRestaurantByIdQuery(Guid Id, bool OnlyActive) : IRequest<RestaurantDto>;
