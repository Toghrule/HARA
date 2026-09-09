using MediatR;

namespace Hara.Application.CompanyInfo.SocialLinks.Commands.DeleteSocialMediaLink;

/// <summary>Admin command to remove a social media link.</summary>
public sealed record DeleteSocialMediaLinkCommand(Guid Id) : IRequest;
