using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using MediatR;

namespace Hara.Application.Venue.Commands.ReviewStaff;

public class ReviewStaffCommandHandler(VenueAccess access, IUnitOfWork unitOfWork)
    : IRequestHandler<ReviewStaffCommand, StaffMemberDto>
{
    public async Task<StaffMemberDto> Handle(ReviewStaffCommand request, CancellationToken cancellationToken)
    {
        var owner = await access.RequireApprovedOwnerAsync(cancellationToken);

        var repository = unitOfWork.Repository<RestaurantMember>();
        var member = await repository.GetByIdAsync(request.MemberId, cancellationToken);

        // Someone else's waiter looks exactly like a missing one, so owners can't probe other restaurants.
        if (member is null || member.RestaurantId != owner.RestaurantId || member.Role != MemberRole.Staff)
        {
            throw new NotFoundException(nameof(RestaurantMember), request.MemberId);
        }

        if (member.Status != MemberStatus.Pending)
        {
            throw new ValidationException("memberId", "This request has already been answered.");
        }

        member.Status = request.Approve ? MemberStatus.Approved : MemberStatus.Rejected;

        repository.Update(member);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return StaffMemberDto.FromEntity(member);
    }
}
