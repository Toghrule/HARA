namespace Hara.Application.Restaurants;

/// <summary>Read model for a <see cref="Hara.Domain.Restaurants.Restaurant"/>, returned by every Restaurants query/command.</summary>
/// <param name="Id">Unique identifier.</param>
/// <param name="Name">Display name.</param>
/// <param name="Description">Free-text description, if any.</param>
/// <param name="Address">Physical address.</param>
/// <param name="PhoneNumber">Public-facing phone number, if any.</param>
/// <param name="ImageUrl">Relative URL of the cover image, if one has been uploaded.</param>
/// <param name="IsActive">Whether the restaurant is currently visible to mobile app users.</param>
/// <param name="CreatedAt">When the restaurant was created.</param>
/// <param name="LastModifiedAt">When the restaurant was last updated, if ever.</param>
public sealed record RestaurantDto(
    Guid Id,
    string Name,
    string? Description,
    string Address,
    string? PhoneNumber,
    string? ImageUrl,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset? LastModifiedAt)
{
    public static RestaurantDto FromEntity(Domain.Restaurants.Restaurant restaurant) => new(
        restaurant.Id,
        restaurant.Name,
        restaurant.Description,
        restaurant.Address,
        restaurant.PhoneNumber,
        restaurant.ImageUrl,
        restaurant.IsActive,
        restaurant.CreatedAt,
        restaurant.LastModifiedAt);
}
