using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Venue;

/// <summary>
/// Works out who the signed-in person is at a restaurant. Every restaurant-side action goes through
/// here, so a person can only ever act for the restaurant their <em>approved</em> membership names — the
/// role in the access token is not enough on its own, because an owner can remove a waiter after the
/// token was issued.
/// </summary>
public class VenueAccess(IUnitOfWork unitOfWork, ICurrentUserService currentUser)
{
    /// <summary>The signed-in person's membership, whatever its status, or <c>null</c> if they have none.</summary>
    public async Task<RestaurantMember?> FindMembershipAsync(CancellationToken cancellationToken)
    {
        var userId = currentUser.UserId;
        if (userId is null)
        {
            return null;
        }

        return await unitOfWork.Repository<RestaurantMember>().Query()
            .Include(m => m.Restaurant)
            .FirstOrDefaultAsync(m => m.UserId == userId, cancellationToken);
    }

    /// <summary>The signed-in person's membership, which must be approved. Anything else is forbidden.</summary>
    public async Task<RestaurantMember> RequireApprovedMemberAsync(CancellationToken cancellationToken)
    {
        var member = await FindMembershipAsync(cancellationToken);

        if (member is null || member.Status != MemberStatus.Approved || member.Restaurant is null)
        {
            throw new ForbiddenException("Your account is not approved for a restaurant yet.");
        }

        return member;
    }

    /// <summary>Like <see cref="RequireApprovedMemberAsync"/>, and the person must be the restaurant's owner.</summary>
    public async Task<RestaurantMember> RequireApprovedOwnerAsync(CancellationToken cancellationToken)
    {
        var member = await RequireApprovedMemberAsync(cancellationToken);

        if (member.Role != MemberRole.Owner)
        {
            throw new ForbiddenException("Only the restaurant's owner can do this.");
        }

        return member;
    }
}
