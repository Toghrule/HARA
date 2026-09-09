using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Application.Restaurants.Submissions.Queries.GetSubmissionById;

public class GetSubmissionByIdQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetSubmissionByIdQuery, RestaurantSubmissionDto>
{
    public async Task<RestaurantSubmissionDto> Handle(GetSubmissionByIdQuery request, CancellationToken cancellationToken)
    {
        var submission = await unitOfWork.Repository<RestaurantSubmission>().GetByIdAsync(request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(RestaurantSubmission), request.Id);

        return RestaurantSubmissionDto.FromEntity(submission);
    }
}
