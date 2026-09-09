using Hara.Domain.Common;

namespace Hara.Domain.CompanyInfo;

/// <summary>A single social media link shown on the mobile app's "About Us" screen.</summary>
public class SocialMediaLink : BaseAuditableEntity
{
    /// <summary>Which platform this link points to (drives the icon shown in the app).</summary>
    public SocialMediaPlatform Platform { get; set; }

    /// <summary>Full URL of the company's profile/page on that platform.</summary>
    public string Url { get; set; } = string.Empty;

    /// <summary>Display position among other links; lower values appear first.</summary>
    public int SortOrder { get; set; }

    /// <summary>Whether the link is currently shown in the mobile app.</summary>
    public bool IsActive { get; set; } = true;
}
