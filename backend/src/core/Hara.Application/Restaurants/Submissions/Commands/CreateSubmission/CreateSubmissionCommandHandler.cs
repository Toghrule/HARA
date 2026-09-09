using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Application.Restaurants.Submissions.Commands.CreateSubmission;

public class CreateSubmissionCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<CreateSubmissionCommand, RestaurantSubmissionDto>
{
    public async Task<RestaurantSubmissionDto> Handle(CreateSubmissionCommand request, CancellationToken cancellationToken)
    {
        var submission = new RestaurantSubmission
        {
            RestaurantName = request.RestaurantName,
            Description = request.Description,
            Address = request.Address,
            PhoneNumber = request.PhoneNumber,
            SubmitterName = request.SubmitterName,
            SubmitterEmail = request.SubmitterEmail,
            SubmitterPhoneNumber = request.SubmitterPhoneNumber,
            Status = SubmissionStatus.Pending
        };

        await unitOfWork.Repository<RestaurantSubmission>().AddAsync(submission, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return RestaurantSubmissionDto.FromEntity(submission);
    }
}
