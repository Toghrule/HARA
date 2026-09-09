using Hara.Domain.Common;

namespace Hara.Domain.Restaurants;

/// <summary>
/// A restaurant published by the admin and shown to mobile app users.
/// Created either directly by an admin or by approving a <see cref="RestaurantSubmission"/>.
/// </summary>
public class Restaurant : BaseAuditableEntity
{
    /// <summary>Display name of the restaurant.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>Free-text description shown on the restaurant's detail screen.</summary>
    public string? Description { get; set; }

    /// <summary>Physical address of the restaurant.</summary>
    public string Address { get; set; } = string.Empty;

    /// <summary>Public-facing phone number, if the restaurant has one.</summary>
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// Relative URL of the restaurant's cover image, as returned by the
    /// upload endpoint. <c>null</c> when no image has been uploaded yet.
    /// </summary>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Whether the restaurant is visible to mobile app users. Admins can
    /// deactivate a restaurant without deleting it (e.g. temporarily closed).
    /// </summary>
    public bool IsActive { get; set; } = true;
}
