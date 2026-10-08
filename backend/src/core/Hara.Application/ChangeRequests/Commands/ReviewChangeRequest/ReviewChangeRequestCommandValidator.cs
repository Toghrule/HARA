using FluentValidation;
using Hara.Domain.Restaurants;

namespace Hara.Application.ChangeRequests.Commands.ReviewChangeRequest;

public class ReviewChangeRequestCommandValidator : AbstractValidator<ReviewChangeRequestCommand>
{
    public ReviewChangeRequestCommandValidator()
    {
        RuleFor(c => c.Id).NotEmpty();
        RuleFor(c => c.Decision)
            .Must(status => status is ChangeRequestStatus.Approved or ChangeRequestStatus.Rejected)
            .WithMessage("Decision must be either Approved or Rejected.");
        RuleFor(c => c.AdminNote).MaximumLength(1000);
    }
}
