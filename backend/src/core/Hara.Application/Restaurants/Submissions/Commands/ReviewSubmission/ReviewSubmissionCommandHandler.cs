using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Application.Restaurants.Submissions.Commands.ReviewSubmission;

public class ReviewSubmissionCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<ReviewSubmissionCommand, RestaurantSubmissionDto>
{
    public async Task<RestaurantSubmissionDto> Handle(ReviewSubmissionCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<RestaurantSubmission>();
        var submission = await repository.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(RestaurantSubmission), request.Id);

        submission.Status = request.Decision;
        submission.AdminNote = request.AdminNote;
        submission.ReviewedAt = DateTimeOffset.UtcNow;

        repository.Update(submission);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return RestaurantSubmissionDto.FromEntity(submission);
    }
}
