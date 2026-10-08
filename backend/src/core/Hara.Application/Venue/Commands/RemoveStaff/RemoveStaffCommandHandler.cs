using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using MediatR;

namespace Hara.Application.Venue.Commands.RemoveStaff;

public class RemoveStaffCommandHandler(VenueAccess access, IUnitOfWork unitOfWork, IIdentityService identityService)
    : IRequestHandler<RemoveStaffCommand>
{
    public async Task Handle(RemoveStaffCommand request, CancellationToken cancellationToken)
    {
        var owner = await access.RequireApprovedOwnerAsync(cancellationToken);

        var member = await unitOfWork.Repository<RestaurantMember>().GetByIdAsync(request.MemberId, cancellationToken);
        if (member is null || member.RestaurantId != owner.RestaurantId || member.Role != MemberRole.Staff)
        {
            throw new NotFoundException(nameof(RestaurantMember), request.MemberId);
        }

        // Deleting the account also removes the membership (cascade) and ends the waiter's sessions.
        await identityService.DeleteUserAsync(member.UserId, cancellationToken);
    }
}
