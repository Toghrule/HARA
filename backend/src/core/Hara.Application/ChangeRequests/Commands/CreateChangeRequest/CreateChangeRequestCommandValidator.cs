using FluentValidation;

namespace Hara.Application.ChangeRequests.Commands.CreateChangeRequest;

public class CreateChangeRequestCommandValidator : AbstractValidator<CreateChangeRequestCommand>
{
    public CreateChangeRequestCommandValidator()
    {
        // The restaurant's name and address can be changed but never emptied.
        RuleFor(c => c.Name).MaximumLength(200).Must(value => value is null || value.Trim().Length > 0)
            .WithMessage("The name can't be empty.");
        RuleFor(c => c.Address).MaximumLength(400).Must(value => value is null || value.Trim().Length > 0)
            .WithMessage("The address can't be empty.");
        RuleFor(c => c.PhoneNumber).MaximumLength(50);
        RuleFor(c => c.Description).MaximumLength(4000);
        RuleFor(c => c.DescriptionRu).MaximumLength(4000);
        RuleFor(c => c.DescriptionEn).MaximumLength(4000);
        RuleFor(c => c.DiscountPercent).InclusiveBetween(0, 100);
        RuleFor(c => c.OwnerNote).MaximumLength(1000);

        RuleFor(c => c)
            .Must(c => c.Name is not null || c.Address is not null || c.PhoneNumber is not null
                || c.Description is not null || c.DescriptionRu is not null || c.DescriptionEn is not null
                || c.DiscountPercent is not null)
            .WithName("changes")
            .WithMessage("Ask for at least one change.");
    }
}
