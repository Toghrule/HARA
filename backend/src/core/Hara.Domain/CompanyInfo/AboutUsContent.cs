using Hara.Domain.Common;

namespace Hara.Domain.CompanyInfo;

/// <summary>
/// The mobile app's "About Us" text. Modeled as a single-row table (a
/// business-rule singleton, not enforced at the database level) because the
/// app only ever shows one about-us page — the admin edits it in place
/// rather than managing a list.
/// </summary>
public class AboutUsContent : BaseAuditableEntity
{
    /// <summary>Company name shown as the page heading.</summary>
    public string CompanyName { get; set; } = string.Empty;

    /// <summary>Main "about us" body text.</summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>Relative URL of the company logo, as returned by the upload endpoint.</summary>
    public string? LogoUrl { get; set; }
}
