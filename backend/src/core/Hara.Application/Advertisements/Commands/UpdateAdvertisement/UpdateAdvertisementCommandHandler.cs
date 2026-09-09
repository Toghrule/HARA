using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Advertisements;
using MediatR;

namespace Hara.Application.Advertisements.Commands.UpdateAdvertisement;

public class UpdateAdvertisementCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<UpdateAdvertisementCommand, AdvertisementDto>
{
    public async Task<AdvertisementDto> Handle(UpdateAdvertisementCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<Advertisement>();
        var advertisement = await repository.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(Advertisement), request.Id);

        advertisement.Title = request.Title;
        advertisement.ImageUrl = request.ImageUrl;
        advertisement.LinkUrl = request.LinkUrl;
        advertisement.SortOrder = request.SortOrder;
        advertisement.IsActive = request.IsActive;

        repository.Update(advertisement);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return AdvertisementDto.FromEntity(advertisement);
    }
}
