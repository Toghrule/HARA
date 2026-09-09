using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.CompanyInfo;
using MediatR;

namespace Hara.Application.CompanyInfo.SocialLinks.Commands.DeleteSocialMediaLink;

public class DeleteSocialMediaLinkCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<DeleteSocialMediaLinkCommand>
{
    public async Task Handle(DeleteSocialMediaLinkCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<SocialMediaLink>();
        var link = await repository.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(SocialMediaLink), request.Id);

        repository.Remove(link);
        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
