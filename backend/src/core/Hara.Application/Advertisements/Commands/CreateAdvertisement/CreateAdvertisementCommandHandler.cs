using Hara.Application.Common.Interfaces;
using Hara.Domain.Advertisements;
using MediatR;

namespace Hara.Application.Advertisements.Commands.CreateAdvertisement;

public class CreateAdvertisementCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<CreateAdvertisementCommand, AdvertisementDto>
{
    public async Task<AdvertisementDto> Handle(CreateAdvertisementCommand request, CancellationToken cancellationToken)
    {
        var advertisement = new Advertisement
        {
            Title = request.Title,
            ImageUrl = request.ImageUrl,
            LinkUrl = request.LinkUrl,
            SortOrder = request.SortOrder,
            IsActive = true
        };

        await unitOfWork.Repository<Advertisement>().AddAsync(advertisement, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return AdvertisementDto.FromEntity(advertisement);
    }
}
