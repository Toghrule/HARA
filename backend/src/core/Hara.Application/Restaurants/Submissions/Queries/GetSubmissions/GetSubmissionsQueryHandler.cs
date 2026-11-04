using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Restaurants.Submissions.Queries.GetSubmissions;

public class GetSubmissionsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetSubmissionsQuery, IReadOnlyList<RestaurantSubmissionDto>>
{
    public async Task<IReadOnlyList<RestaurantSubmissionDto>> Handle(GetSubmissionsQuery request, CancellationToken cancellationToken)
    {
        var query = unitOfWork.Repository<RestaurantSubmission>().Query();

        if (request.Status is not null)
        {
            query = query.Where(s => s.Status == request.Status);
        }

        // An owner who has not confirmed their email is not shown: the registration may be made up.
        var unconfirmed = unitOfWork.Repository<Domain.Members.EmailVerification>().Query().Select(v => v.UserId);
        query = query.Where(s => s.OwnerUserId == null || !unconfirmed.Contains(s.OwnerUserId.Value));

        var submissions = await query.OrderByDescending(s => s.CreatedAt).ToListAsync(cancellationToken);

        return submissions.Select(RestaurantSubmissionDto.FromEntity).ToList();
    }
}
