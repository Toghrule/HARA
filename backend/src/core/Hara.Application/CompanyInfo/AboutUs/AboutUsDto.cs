using Hara.Application.Common;
using Hara.Domain.CompanyInfo;

namespace Hara.Application.CompanyInfo.AboutUs;

/// <summary>
/// Read model for the mobile app's "About Us" content. Always resolvable —
/// if no <see cref="AboutUsContent"/> row exists yet, <see cref="Id"/> is
/// <see cref="Guid.Empty"/> and the text fields are empty, so the admin panel
/// always has something to render an edit form around.
/// </summary>
/// <param name="Description">Azerbaijani text — or the requested language, after <see cref="Localize"/>.</param>
/// <param name="DescriptionRu">Russian translation, if filled in.</param>
/// <param name="DescriptionEn">English translation, if filled in.</param>
public sealed record AboutUsDto(
    Guid Id,
    string CompanyName,
    string Description,
    string? LogoUrl,
    DateTimeOffset? LastModifiedAt,
    string? DescriptionRu = null,
    string? DescriptionEn = null)
{
    public static AboutUsDto FromEntity(AboutUsContent content) => new(
        content.Id,
        content.CompanyName,
        content.Description,
        content.LogoUrl,
        content.LastModifiedAt,
        content.DescriptionRu,
        content.DescriptionEn);

    /// <summary>Placeholder returned when no about-us content has been saved yet.</summary>
    public static AboutUsDto Empty { get; } = new(Guid.Empty, string.Empty, string.Empty, null, null);

    /// <summary>Returns a copy whose <see cref="Description"/> is the text in <paramref name="language"/> (falling back to Azerbaijani).</summary>
    public AboutUsDto Localize(string? language) =>
        this with { Description = Localization.Pick(language, Description, DescriptionRu, DescriptionEn) ?? string.Empty };
}
