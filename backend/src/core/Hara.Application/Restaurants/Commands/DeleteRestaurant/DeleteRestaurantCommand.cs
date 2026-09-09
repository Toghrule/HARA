using MediatR;

namespace Hara.Application.Restaurants.Commands.DeleteRestaurant;

/// <summary>Admin command to permanently delete a <see cref="Domain.Restaurants.Restaurant"/>. Prefer deactivating (see <c>UpdateRestaurantCommand.IsActive</c>) unless it should truly disappear.</summary>
public sealed record DeleteRestaurantCommand(Guid Id) : IRequest;
