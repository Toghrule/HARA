using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Application.Restaurants.Submissions.Commands.DeleteSubmission;

public class DeleteSubmissionCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<DeleteSubmissionCommand>
{
    public async Task Handle(DeleteSubmissionCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<RestaurantSubmission>();
        var submission = await repository.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(RestaurantSubmission), request.Id);

        repository.Remove(submission);
        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
