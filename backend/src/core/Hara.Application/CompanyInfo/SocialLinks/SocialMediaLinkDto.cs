using Hara.Domain.CompanyInfo;

namespace Hara.Application.CompanyInfo.SocialLinks;

/// <summary>Read model for a <see cref="SocialMediaLink"/>.</summary>
public sealed record SocialMediaLinkDto(
    Guid Id,
    SocialMediaPlatform Platform,
    string Url,
    int SortOrder,
    bool IsActive)
{
    public static SocialMediaLinkDto FromEntity(SocialMediaLink link) => new(
        link.Id,
        link.Platform,
        link.Url,
        link.SortOrder,
        link.IsActive);
}
