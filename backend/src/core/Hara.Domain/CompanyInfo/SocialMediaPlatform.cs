namespace Hara.Domain.CompanyInfo;

/// <summary>Recognized social media platforms for a <see cref="SocialMediaLink"/>, used to pick the right icon in the mobile app.</summary>
public enum SocialMediaPlatform
{
    Facebook = 0,
    Instagram = 1,
    X = 2,
    TikTok = 3,
    YouTube = 4,
    LinkedIn = 5,
    Website = 6,

    /// <summary>Any platform not covered by the specific values above.</summary>
    Other = 99
}
