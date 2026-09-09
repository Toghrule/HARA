using FluentValidation;

namespace Hara.Application.Restaurants.Submissions.Commands.CreateSubmission;

public class CreateSubmissionCommandValidator : AbstractValidator<CreateSubmissionCommand>
{
    public CreateSubmissionCommandValidator()
    {
        RuleFor(c => c.RestaurantName).NotEmpty().MaximumLength(200);
        RuleFor(c => c.Address).MaximumLength(400);
        RuleFor(c => c.PhoneNumber).MaximumLength(50);
        RuleFor(c => c.Description).MaximumLength(4000);
        RuleFor(c => c.SubmitterName).NotEmpty().MaximumLength(200);
        RuleFor(c => c.SubmitterEmail).EmailAddress().MaximumLength(320).When(c => !string.IsNullOrWhiteSpace(c.SubmitterEmail));
        RuleFor(c => c.SubmitterPhoneNumber).MaximumLength(50);

        RuleFor(c => c)
            .Must(c => !string.IsNullOrWhiteSpace(c.SubmitterEmail) || !string.IsNullOrWhiteSpace(c.SubmitterPhoneNumber))
            .WithMessage("Provide at least an email or a phone number so we can follow up with you.")
            .WithName("SubmitterEmail");
    }
}
