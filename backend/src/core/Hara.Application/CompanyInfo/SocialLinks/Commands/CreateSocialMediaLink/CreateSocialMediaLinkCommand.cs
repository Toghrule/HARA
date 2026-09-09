using Hara.Domain.CompanyInfo;
using MediatR;

namespace Hara.Application.CompanyInfo.SocialLinks.Commands.CreateSocialMediaLink;

/// <summary>Admin command to add a social media link to the "About Us" screen.</summary>
public sealed record CreateSocialMediaLinkCommand(SocialMediaPlatform Platform, string Url, int SortOrder) : IRequest<SocialMediaLinkDto>;
