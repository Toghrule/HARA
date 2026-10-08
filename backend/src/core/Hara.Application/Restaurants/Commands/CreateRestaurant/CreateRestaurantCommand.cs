using MediatR;

namespace Hara.Application.Restaurants.Commands.CreateRestaurant;

/// <summary>Admin command to create a new <see cref="Domain.Restaurants.Restaurant"/>.</summary>
/// <param name="Name">Display name.</param>
/// <param name="Description">Optional free-text description.</param>
/// <param name="Address">Physical address.</param>
/// <param name="Latitude">Latitude of the restaurant's exact location, in decimal degrees.</param>
/// <param name="Longitude">Longitude of the restaurant's exact location, in decimal degrees.</param>
/// <param name="PhoneNumber">Optional public-facing phone number.</param>
/// <param name="ImageUrl">Optional cover image URL, from a prior upload.</param>
/// <param name="DiscountPercent">Percentage (0–100) off the table bill for customers with a valid reservation code.</param>
/// <param name="FromSubmissionId">The registration this restaurant is created from, if any. The submission is marked approved and, if an owner registered it, that account becomes the restaurant's owner.</param>
public sealed record CreateRestaurantCommand(
    string Name,
    string? Description,
    string Address,
    double Latitude,
    double Longitude,
    string? PhoneNumber,
    string? ImageUrl,
    int DiscountPercent,
    string? DescriptionRu = null,
    string? DescriptionEn = null,
    Guid? FromSubmissionId = null) : IRequest<RestaurantDto>;
