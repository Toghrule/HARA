using FluentValidation;

namespace Hara.Application.Faq.Commands.CreateFaqItem;

public class CreateFaqItemCommandValidator : AbstractValidator<CreateFaqItemCommand>
{
    public CreateFaqItemCommandValidator()
    {
        RuleFor(c => c.Question).NotEmpty().MaximumLength(500);
        RuleFor(c => c.Answer).NotEmpty().MaximumLength(4000);
    }
}
