using Hara.Domain.Members;
using Hara.Domain.Restaurants;

namespace Hara.Application.Venue;

/// <summary>The restaurant a member works at, as shown in their part of the app.</summary>
public sealed record VenueRestaurantDto(Guid Id, string Name, string Address, int DiscountPercent, string? ImageUrl)
{
    public static VenueRestaurantDto FromEntity(Restaurant restaurant) =>
        new(restaurant.Id, restaurant.Name, restaurant.Address, restaurant.DiscountPercent, restaurant.ImageUrl);
}

/// <summary>Where the signed-in owner or waiter stands: what they can do in the app right now.</summary>
/// <param name="Role"><c>Owner</c> or <c>Staff</c>.</param>
/// <param name="Status"><c>Pending</c> (waiting for approval), <c>Approved</c>, <c>Rejected</c>, or <c>None</c> (nothing on record, e.g. the registration was deleted).</param>
/// <param name="FullName">The person's name, when known.</param>
/// <param name="Restaurant">The restaurant, once approved.</param>
/// <param name="Note">The reason given when an owner registration was declined.</param>
public sealed record VenueMeDto(string Role, string Status, string? FullName, VenueRestaurantDto? Restaurant, string? Note);

/// <summary>A person on a restaurant's team, for the owner's staff screen.</summary>
public sealed record StaffMemberDto(
    Guid Id,
    string FullName,
    string Email,
    string? PhoneNumber,
    MemberRole Role,
    MemberStatus Status,
    DateTimeOffset CreatedAt)
{
    public static StaffMemberDto FromEntity(RestaurantMember member) => new(
        member.Id,
        member.FullName,
        member.Email,
        member.PhoneNumber,
        member.Role,
        member.Status,
        member.CreatedAt);
}
