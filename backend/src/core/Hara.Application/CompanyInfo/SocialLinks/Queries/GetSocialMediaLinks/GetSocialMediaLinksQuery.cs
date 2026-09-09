using MediatR;

namespace Hara.Application.CompanyInfo.SocialLinks.Queries.GetSocialMediaLinks;

/// <summary>Lists social media links ordered for display. The public endpoint passes <paramref name="OnlyActive"/> = <c>true</c>; the admin endpoint passes <c>false</c>.</summary>
public sealed record GetSocialMediaLinksQuery(bool OnlyActive) : IRequest<IReadOnlyList<SocialMediaLinkDto>>;
