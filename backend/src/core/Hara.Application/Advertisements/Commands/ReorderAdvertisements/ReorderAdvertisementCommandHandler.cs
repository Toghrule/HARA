using Hara.Application.Common.Interfaces;
using Hara.Domain.Advertisements;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Advertisements.Commands.ReorderAdvertisements;

public class ReorderAdvertisementCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<ReorderAdvertisementCommand>
{
    public async Task Handle(ReorderAdvertisementCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<Advertisement>();
        var advertisements = await repository.Query()
            .Where(a => request.OrderedIds.Contains(a.Id))
            .ToListAsync(cancellationToken);

        for (var i = 0; i < request.OrderedIds.Count; i++)
        {
            var id = request.OrderedIds[i];
            var advertisement = advertisements.FirstOrDefault(a => a.Id == id);

            if (advertisement is null)
            {
                continue;
            }

            advertisement.SortOrder = i;
            repository.Update(advertisement);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
