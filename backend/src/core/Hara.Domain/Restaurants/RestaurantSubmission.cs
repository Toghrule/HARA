using Hara.Domain.Common;

namespace Hara.Domain.Restaurants;

/// <summary>
/// A "add your restaurant" request submitted anonymously from the mobile app.
/// Kept separate from <see cref="Restaurant"/> because a submission is unverified,
/// user-supplied data that only becomes a real <see cref="Restaurant"/> once an
/// admin reviews and (manually) creates it — the two have different lifecycles
/// and different trust levels.
/// </summary>
public class RestaurantSubmission : BaseAuditableEntity
{
    /// <summary>Restaurant name as reported by the submitter.</summary>
    public string RestaurantName { get; set; } = string.Empty;

    /// <summary>Free-text description as reported by the submitter.</summary>
    public string? Description { get; set; }

    /// <summary>Address as reported by the submitter.</summary>
    public string? Address { get; set; }

    /// <summary>Restaurant phone number as reported by the submitter.</summary>
    public string? PhoneNumber { get; set; }

    /// <summary>Name of the person submitting the request, so the admin knows who to credit or follow up with.</summary>
    public string SubmitterName { get; set; } = string.Empty;

    /// <summary>Email address to contact the submitter back, if provided.</summary>
    public string? SubmitterEmail { get; set; }

    /// <summary>Phone number to contact the submitter back, if provided.</summary>
    public string? SubmitterPhoneNumber { get; set; }

    /// <summary>Current review state. Starts at <see cref="SubmissionStatus.Pending"/>.</summary>
    public SubmissionStatus Status { get; set; } = SubmissionStatus.Pending;

    /// <summary>Optional note left by the admin when reviewing (e.g. a rejection reason).</summary>
    public string? AdminNote { get; set; }

    /// <summary>When the submission was last reviewed by an admin, or <c>null</c> while still <see cref="SubmissionStatus.Pending"/>.</summary>
    public DateTimeOffset? ReviewedAt { get; set; }
}
