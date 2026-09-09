using Hara.Domain.Common;

namespace Hara.Domain.Advertisements;

/// <summary>
/// A single slide in the mobile app's ad carousel. Multiple active ads are
/// shown in <see cref="SortOrder"/> sequence.
/// </summary>
public class Advertisement : BaseAuditableEntity
{
    /// <summary>Optional headline shown over/under the image.</summary>
    public string? Title { get; set; }

    /// <summary>Relative URL of the ad's image, as returned by the upload endpoint.</summary>
    public string ImageUrl { get; set; } = string.Empty;

    /// <summary>
    /// Where tapping the ad should take the user (e.g. an external URL or a
    /// deep link such as a restaurant id). Optional — a purely informational
    /// ad can have no destination.
    /// </summary>
    public string? LinkUrl { get; set; }

    /// <summary>Position within the carousel; lower values appear first.</summary>
    public int SortOrder { get; set; }

    /// <summary>Whether the ad is currently shown in the mobile app carousel.</summary>
    public bool IsActive { get; set; } = true;
}
