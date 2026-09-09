using FluentValidation;

namespace Hara.Application.Faq.Commands.ReorderFaqItems;

public class ReorderFaqItemsCommandValidator : AbstractValidator<ReorderFaqItemsCommand>
{
    public ReorderFaqItemsCommandValidator()
    {
        RuleFor(c => c.OrderedIds).NotEmpty();
    }
}
