using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.CompanyInfo;
using MediatR;

namespace Hara.Application.CompanyInfo.SocialLinks.Commands.UpdateSocialMediaLink;

public class UpdateSocialMediaLinkCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<UpdateSocialMediaLinkCommand, SocialMediaLinkDto>
{
    public async Task<SocialMediaLinkDto> Handle(UpdateSocialMediaLinkCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<SocialMediaLink>();
        var link = await repository.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(SocialMediaLink), request.Id);

        link.Platform = request.Platform;
        link.Url = request.Url;
        link.SortOrder = request.SortOrder;
        link.IsActive = request.IsActive;

        repository.Update(link);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return SocialMediaLinkDto.FromEntity(link);
    }
}
