using FluentValidation;
using Hara.Domain.Restaurants;

namespace Hara.Application.Restaurants.Submissions.Commands.ReviewSubmission;

public class ReviewSubmissionCommandValidator : AbstractValidator<ReviewSubmissionCommand>
{
    public ReviewSubmissionCommandValidator()
    {
        RuleFor(c => c.Id).NotEmpty();
        RuleFor(c => c.Decision)
            .Must(status => status is SubmissionStatus.Approved or SubmissionStatus.Rejected)
            .WithMessage("Decision must be either Approved or Rejected.");
        RuleFor(c => c.AdminNote).MaximumLength(1000);
    }
}
