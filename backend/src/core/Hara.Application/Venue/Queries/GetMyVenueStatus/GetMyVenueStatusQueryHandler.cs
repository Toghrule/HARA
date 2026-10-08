using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Venue.Queries.GetMyVenueStatus;

public class GetMyVenueStatusQueryHandler(VenueAccess access, IUnitOfWork unitOfWork, ICurrentUserService currentUser)
    : IRequestHandler<GetMyVenueStatusQuery, VenueMeDto>
{
    public async Task<VenueMeDto> Handle(GetMyVenueStatusQuery request, CancellationToken cancellationToken)
    {
        var userId = currentUser.UserId ?? throw new ForbiddenException();

        var member = await access.FindMembershipAsync(cancellationToken);
        if (member is not null)
        {
            return new VenueMeDto(
                member.Role.ToString(),
                member.Status.ToString(),
                member.FullName,
                member.Status == MemberStatus.Approved && member.Restaurant is not null
                    ? VenueRestaurantDto.FromEntity(member.Restaurant)
                    : null,
                null);
        }

        // An owner has no membership until the admin creates their restaurant; until then their
        // registration is what says where they stand.
        var submission = await unitOfWork.Repository<RestaurantSubmission>().Query()
            .Where(s => s.OwnerUserId == userId)
            .OrderByDescending(s => s.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (submission is null)
        {
            return new VenueMeDto("None", "None", null, null, null);
        }

        var status = submission.Status == SubmissionStatus.Rejected ? MemberStatus.Rejected.ToString() : MemberStatus.Pending.ToString();

        return new VenueMeDto(MemberRole.Owner.ToString(), status, submission.SubmitterName, null, submission.AdminNote);
    }
}
