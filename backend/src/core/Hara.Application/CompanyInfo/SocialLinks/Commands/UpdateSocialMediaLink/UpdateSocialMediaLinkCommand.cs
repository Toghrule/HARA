using Hara.Domain.CompanyInfo;
using MediatR;

namespace Hara.Application.CompanyInfo.SocialLinks.Commands.UpdateSocialMediaLink;

/// <summary>Admin command to update an existing social media link, including its visibility.</summary>
public sealed record UpdateSocialMediaLinkCommand(Guid Id, SocialMediaPlatform Platform, string Url, int SortOrder, bool IsActive) : IRequest<SocialMediaLinkDto>;
