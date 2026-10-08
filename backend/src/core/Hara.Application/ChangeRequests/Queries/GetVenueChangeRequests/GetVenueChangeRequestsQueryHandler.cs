using Hara.Application.Common.Interfaces;
using Hara.Application.Venue;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.ChangeRequests.Queries.GetVenueChangeRequests;

public class GetVenueChangeRequestsQueryHandler(VenueAccess access, IUnitOfWork unitOfWork)
    : IRequestHandler<GetVenueChangeRequestsQuery, IReadOnlyList<ChangeRequestDto>>
{
    public async Task<IReadOnlyList<ChangeRequestDto>> Handle(GetVenueChangeRequestsQuery request, CancellationToken cancellationToken)
    {
        var owner = await access.RequireApprovedOwnerAsync(cancellationToken);

        var requests = await unitOfWork.Repository<RestaurantChangeRequest>().Query()
            .Include(c => c.Restaurant)
            .Where(c => c.RestaurantId == owner.RestaurantId)
            .OrderByDescending(c => c.CreatedAt)
            .Take(50)
            .ToListAsync(cancellationToken);

        return requests.Select(ChangeRequestDto.FromEntity).ToList();
    }
}
