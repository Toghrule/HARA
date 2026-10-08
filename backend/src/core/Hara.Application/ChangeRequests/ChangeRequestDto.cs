using Hara.Domain.Restaurants;

namespace Hara.Application.ChangeRequests;

/// <summary>What the restaurant shows right now, next to what the owner asks for, so a reviewer sees the difference.</summary>
public sealed record RestaurantSnapshotDto(
    string Name,
    string Address,
    string? PhoneNumber,
    string? Description,
    string? DescriptionRu,
    string? DescriptionEn,
    int DiscountPercent)
{
    public static RestaurantSnapshotDto FromEntity(Restaurant restaurant) => new(
        restaurant.Name,
        restaurant.Address,
        restaurant.PhoneNumber,
        restaurant.Description,
        restaurant.DescriptionRu,
        restaurant.DescriptionEn,
        restaurant.DiscountPercent);
}

/// <summary>
/// Read model for a <see cref="RestaurantChangeRequest"/>. Requested fields that are <c>null</c> are not being
/// changed; an empty string asks to remove an optional text.
/// </summary>
/// <param name="Current">The restaurant as it is now (after the change, once the request was approved).</param>
public sealed record ChangeRequestDto(
    Guid Id,
    Guid RestaurantId,
    string RestaurantName,
    string? Name,
    string? Address,
    string? PhoneNumber,
    string? Description,
    string? DescriptionRu,
    string? DescriptionEn,
    int? DiscountPercent,
    string? OwnerNote,
    ChangeRequestStatus Status,
    string? AdminNote,
    DateTimeOffset? ReviewedAt,
    DateTimeOffset CreatedAt,
    RestaurantSnapshotDto Current)
{
    /// <summary>Maps an entity whose <see cref="RestaurantChangeRequest.Restaurant"/> has been loaded.</summary>
    public static ChangeRequestDto FromEntity(RestaurantChangeRequest request) => new(
        request.Id,
        request.RestaurantId,
        request.Restaurant!.Name,
        request.Name,
        request.Address,
        request.PhoneNumber,
        request.Description,
        request.DescriptionRu,
        request.DescriptionEn,
        request.DiscountPercent,
        request.OwnerNote,
        request.Status,
        request.AdminNote,
        request.ReviewedAt,
        request.CreatedAt,
        RestaurantSnapshotDto.FromEntity(request.Restaurant));
}
