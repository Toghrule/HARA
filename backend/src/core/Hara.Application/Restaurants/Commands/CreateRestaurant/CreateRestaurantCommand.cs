using MediatR;

namespace Hara.Application.Restaurants.Commands.CreateRestaurant;

/// <summary>Admin command to create a new <see cref="Domain.Restaurants.Restaurant"/>.</summary>
/// <param name="Name">Display name.</param>
/// <param name="Description">Optional free-text description.</param>
/// <param name="Address">Physical address.</param>
/// <param name="PhoneNumber">Optional public-facing phone number.</param>
/// <param name="ImageUrl">Optional cover image URL, from a prior upload.</param>
public sealed record CreateRestaurantCommand(
    string Name,
    string? Description,
    string Address,
    string? PhoneNumber,
    string? ImageUrl) : IRequest<RestaurantDto>;
