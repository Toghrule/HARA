using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.ChangeRequests.Queries.GetChangeRequests;

public class GetChangeRequestsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetChangeRequestsQuery, IReadOnlyList<ChangeRequestDto>>
{
    public async Task<IReadOnlyList<ChangeRequestDto>> Handle(GetChangeRequestsQuery request, CancellationToken cancellationToken)
    {
        var query = unitOfWork.Repository<RestaurantChangeRequest>().Query().Include(c => c.Restaurant).AsQueryable();

        if (request.Status is not null)
        {
            query = query.Where(c => c.Status == request.Status);
        }

        var requests = await query.OrderByDescending(c => c.CreatedAt).Take(200).ToListAsync(cancellationToken);

        return requests.Select(ChangeRequestDto.FromEntity).ToList();
    }
}
