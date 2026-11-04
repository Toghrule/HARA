using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Restaurants.Queries.GetRestaurantOwner;

/// <summary>Admin query: who the owner of a restaurant is, or <c>null</c> when it has none yet (so the admin can give it one).</summary>
public sealed record GetRestaurantOwnerQuery(Guid RestaurantId) : IRequest<RestaurantOwnerDto?>;

public sealed record RestaurantOwnerDto(string FullName, string Email, string? PhoneNumber);

public class GetRestaurantOwnerQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetRestaurantOwnerQuery, RestaurantOwnerDto?>
{
    public async Task<RestaurantOwnerDto?> Handle(GetRestaurantOwnerQuery request, CancellationToken cancellationToken) =>
        await unitOfWork.Repository<RestaurantMember>().Query()
            .Where(m => m.RestaurantId == request.RestaurantId && m.Role == MemberRole.Owner)
            .Select(m => new RestaurantOwnerDto(m.FullName, m.Email, m.PhoneNumber))
            .FirstOrDefaultAsync(cancellationToken);
}
