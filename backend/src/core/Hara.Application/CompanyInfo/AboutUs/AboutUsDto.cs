using Hara.Domain.CompanyInfo;

namespace Hara.Application.CompanyInfo.AboutUs;

/// <summary>
/// Read model for the mobile app's "About Us" content. Always resolvable —
/// if no <see cref="AboutUsContent"/> row exists yet, <see cref="Id"/> is
/// <see cref="Guid.Empty"/> and the text fields are empty, so the admin panel
/// always has something to render an edit form around.
/// </summary>
public sealed record AboutUsDto(
    Guid Id,
    string CompanyName,
    string Description,
    string? LogoUrl,
    DateTimeOffset? LastModifiedAt)
{
    public static AboutUsDto FromEntity(AboutUsContent content) => new(
        content.Id,
        content.CompanyName,
        content.Description,
        content.LogoUrl,
        content.LastModifiedAt);

    /// <summary>Placeholder returned when no about-us content has been saved yet.</summary>
    public static AboutUsDto Empty { get; } = new(Guid.Empty, string.Empty, string.Empty, null, null);
}
