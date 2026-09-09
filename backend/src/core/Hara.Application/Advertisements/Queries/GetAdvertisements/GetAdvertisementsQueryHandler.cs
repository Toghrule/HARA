using Hara.Application.Common.Interfaces;
using Hara.Domain.Advertisements;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Advertisements.Queries.GetAdvertisements;

public class GetAdvertisementsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetAdvertisementsQuery, IReadOnlyList<AdvertisementDto>>
{
    public async Task<IReadOnlyList<AdvertisementDto>> Handle(GetAdvertisementsQuery request, CancellationToken cancellationToken)
    {
        var query = unitOfWork.Repository<Advertisement>().Query();

        if (request.OnlyActive)
        {
            query = query.Where(a => a.IsActive);
        }

        var advertisements = await query.OrderBy(a => a.SortOrder).ToListAsync(cancellationToken);

        return advertisements.Select(AdvertisementDto.FromEntity).ToList();
    }
}
