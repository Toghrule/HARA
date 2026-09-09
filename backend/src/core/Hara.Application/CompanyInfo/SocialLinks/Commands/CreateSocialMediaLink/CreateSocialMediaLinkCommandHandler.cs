using Hara.Application.Common.Interfaces;
using Hara.Domain.CompanyInfo;
using MediatR;

namespace Hara.Application.CompanyInfo.SocialLinks.Commands.CreateSocialMediaLink;

public class CreateSocialMediaLinkCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<CreateSocialMediaLinkCommand, SocialMediaLinkDto>
{
    public async Task<SocialMediaLinkDto> Handle(CreateSocialMediaLinkCommand request, CancellationToken cancellationToken)
    {
        var link = new SocialMediaLink
        {
            Platform = request.Platform,
            Url = request.Url,
            SortOrder = request.SortOrder
        };

        await unitOfWork.Repository<SocialMediaLink>().AddAsync(link, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return SocialMediaLinkDto.FromEntity(link);
    }
}
