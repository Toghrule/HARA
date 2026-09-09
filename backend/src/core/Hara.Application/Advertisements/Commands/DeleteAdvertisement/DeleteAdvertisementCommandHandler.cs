using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Advertisements;
using MediatR;

namespace Hara.Application.Advertisements.Commands.DeleteAdvertisement;

public class DeleteAdvertisementCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<DeleteAdvertisementCommand>
{
    public async Task Handle(DeleteAdvertisementCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<Advertisement>();
        var advertisement = await repository.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(Advertisement), request.Id);

        repository.Remove(advertisement);
        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
