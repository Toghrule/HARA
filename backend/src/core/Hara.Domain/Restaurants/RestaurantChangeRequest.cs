using Hara.Domain.Common;

namespace Hara.Domain.Restaurants;

/// <summary>Review state of a <see cref="RestaurantChangeRequest"/>.</summary>
public enum ChangeRequestStatus
{
    /// <summary>Sent by the restaurant's owner and not yet reviewed by an admin.</summary>
    Pending = 0,

    /// <summary>Accepted by an admin; the changes were applied to the restaurant.</summary>
    Approved = 1,

    /// <summary>Declined by an admin, optionally with a reason in <see cref="RestaurantChangeRequest.AdminNote"/>.</summary>
    Rejected = 2
}

/// <summary>
/// A restaurant owner's request to change what the app shows about their restaurant. Owners can't edit
/// the restaurant directly: the admin reviews the request and, if they approve it, the changes are applied.
/// Every field is optional and <c>null</c> means "leave as is"; at least one is set.
/// </summary>
public class RestaurantChangeRequest : BaseAuditableEntity
{
    /// <summary>The restaurant the owner wants changed.</summary>
    public Guid RestaurantId { get; set; }

    /// <summary>The restaurant the owner wants changed.</summary>
    public Restaurant? Restaurant { get; set; }

    /// <summary>The owner's account that sent the request.</summary>
    public Guid? RequestedByUserId { get; set; }

    public string? Name { get; set; }

    public string? Address { get; set; }

    /// <summary>New phone number; an empty string asks to remove it.</summary>
    public string? PhoneNumber { get; set; }

    /// <summary>New Azerbaijani description; an empty string asks to remove it.</summary>
    public string? Description { get; set; }

    /// <summary>New Russian description; an empty string asks to remove it.</summary>
    public string? DescriptionRu { get; set; }

    /// <summary>New English description; an empty string asks to remove it.</summary>
    public string? DescriptionEn { get; set; }

    /// <summary>New discount (0–100) customers get with a reservation code.</summary>
    public int? DiscountPercent { get; set; }

    /// <summary>A message from the owner explaining the request.</summary>
    public string? OwnerNote { get; set; }

    public ChangeRequestStatus Status { get; set; } = ChangeRequestStatus.Pending;

    /// <summary>Optional note left by the admin when reviewing (e.g. a rejection reason).</summary>
    public string? AdminNote { get; set; }

    /// <summary>When an admin reviewed the request, or <c>null</c> while it is pending.</summary>
    public DateTimeOffset? ReviewedAt { get; set; }
}
