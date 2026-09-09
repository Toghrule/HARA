using FluentValidation;

namespace Hara.Application.Faq.Commands.UpdateFaqItem;

public class UpdateFaqItemCommandValidator : AbstractValidator<UpdateFaqItemCommand>
{
    public UpdateFaqItemCommandValidator()
    {
        RuleFor(c => c.Id).NotEmpty();
        RuleFor(c => c.Question).NotEmpty().MaximumLength(500);
        RuleFor(c => c.Answer).NotEmpty().MaximumLength(4000);
    }
}
