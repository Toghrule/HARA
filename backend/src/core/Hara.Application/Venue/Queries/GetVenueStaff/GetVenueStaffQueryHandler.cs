using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Venue.Queries.GetVenueStaff;

public class GetVenueStaffQueryHandler(VenueAccess access, IUnitOfWork unitOfWork)
    : IRequestHandler<GetVenueStaffQuery, IReadOnlyList<StaffMemberDto>>
{
    public async Task<IReadOnlyList<StaffMemberDto>> Handle(GetVenueStaffQuery request, CancellationToken cancellationToken)
    {
        var owner = await access.RequireApprovedOwnerAsync(cancellationToken);

        var members = await unitOfWork.Repository<RestaurantMember>().Query()
            .Where(m => m.RestaurantId == owner.RestaurantId)
            .ToListAsync(cancellationToken);

        return members
            .OrderBy(m => m.Status == MemberStatus.Pending ? 0 : 1)
            .ThenBy(m => m.Role)
            .ThenBy(m => m.FullName, StringComparer.CurrentCultureIgnoreCase)
            .Select(StaffMemberDto.FromEntity)
            .ToList();
    }
}
