using Hara.Application.Common;

namespace Hara.Application.Restaurants;

/// <summary>Read model for a <see cref="Hara.Domain.Restaurants.Restaurant"/>, returned by every Restaurants query/command.</summary>
/// <param name="Id">Unique identifier.</param>
/// <param name="Name">Display name.</param>
/// <param name="Description">Free-text description, if any (Azerbaijani — or the requested language, after <see cref="Localize"/>).</param>
/// <param name="Address">Physical address.</param>
/// <param name="Latitude">Latitude of the restaurant's exact location, in decimal degrees.</param>
/// <param name="Longitude">Longitude of the restaurant's exact location, in decimal degrees.</param>
/// <param name="PhoneNumber">Public-facing phone number, if any.</param>
/// <param name="ImageUrl">Relative URL of the cover image, if one has been uploaded.</param>
/// <param name="DiscountPercent">Percentage (0–100) off the table bill when a customer presents a valid reservation code.</param>
/// <param name="IsActive">Whether the restaurant is currently visible to mobile app users.</param>
/// <param name="CreatedAt">When the restaurant was created.</param>
/// <param name="LastModifiedAt">When the restaurant was last updated, if ever.</param>
/// <param name="DescriptionRu">Russian translation of the description, if filled in.</param>
/// <param name="DescriptionEn">English translation of the description, if filled in.</param>
public sealed record RestaurantDto(
    Guid Id,
    string Name,
    string? Description,
    string Address,
    double Latitude,
    double Longitude,
    string? PhoneNumber,
    string? ImageUrl,
    int DiscountPercent,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset? LastModifiedAt,
    string? DescriptionRu = null,
    string? DescriptionEn = null)
{
    public static RestaurantDto FromEntity(Domain.Restaurants.Restaurant restaurant) => new(
        restaurant.Id,
        restaurant.Name,
        restaurant.Description,
        restaurant.Address,
        restaurant.Latitude,
        restaurant.Longitude,
        restaurant.PhoneNumber,
        restaurant.ImageUrl,
        restaurant.DiscountPercent,
        restaurant.IsActive,
        restaurant.CreatedAt,
        restaurant.LastModifiedAt,
        restaurant.DescriptionRu,
        restaurant.DescriptionEn);

    /// <summary>Returns a copy whose <see cref="Description"/> is the text in <paramref name="language"/> (falling back to Azerbaijani).</summary>
    public RestaurantDto Localize(string? language) =>
        this with { Description = Localization.Pick(language, Description, DescriptionRu, DescriptionEn) };
}
