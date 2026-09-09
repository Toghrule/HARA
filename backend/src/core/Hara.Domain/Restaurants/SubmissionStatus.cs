namespace Hara.Domain.Restaurants;

/// <summary>Review state of a <see cref="RestaurantSubmission"/> in the admin panel.</summary>
public enum SubmissionStatus
{
    /// <summary>Submitted by a mobile app user and not yet reviewed by an admin.</summary>
    Pending = 0,

    /// <summary>Reviewed and accepted by an admin. Does not by itself create a <see cref="Restaurant"/> — the admin still creates one, informed by the submission.</summary>
    Approved = 1,

    /// <summary>Reviewed and declined by an admin, optionally with a reason in <see cref="RestaurantSubmission.AdminNote"/>.</summary>
    Rejected = 2
}
