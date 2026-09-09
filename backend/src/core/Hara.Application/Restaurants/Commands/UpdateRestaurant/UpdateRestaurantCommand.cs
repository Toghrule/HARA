using MediatR;

namespace Hara.Application.Restaurants.Commands.UpdateRestaurant;

/// <summary>Admin command to update every editable field of an existing <see cref="Domain.Restaurants.Restaurant"/>, including its visibility.</summary>
public sealed record UpdateRestaurantCommand(
    Guid Id,
    string Name,
    string? Description,
    string Address,
    string? PhoneNumber,
    string? ImageUrl,
    bool IsActive) : IRequest<RestaurantDto>;
