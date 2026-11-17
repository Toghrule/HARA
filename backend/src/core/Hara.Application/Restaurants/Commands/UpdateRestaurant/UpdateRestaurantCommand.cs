using MediatR;

namespace Hara.Application.Restaurants.Commands.UpdateRestaurant;

/// <summary>
/// Admin command to update every editable field of an existing <see cref="Domain.Restaurants.Restaurant"/>, including its visibility.
/// <paramref name="Cuisines"/> and <paramref name="GalleryUrls"/> left <c>null</c> stay as they are; an empty list clears them.
/// The two featured dates and the district are always taken as sent: both dates empty means the restaurant is not one of the week's picks,
/// an empty district means none.
/// </summary>
public sealed record UpdateRestaurantCommand(
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
    string? DescriptionRu = null,
    string? DescriptionEn = null,
    IReadOnlyList<string>? Cuisines = null,
    IReadOnlyList<string>? GalleryUrls = null,
    DateOnly? FeaturedFrom = null,
    DateOnly? FeaturedUntil = null,
    string? District = null) : IRequest<RestaurantDto>;
