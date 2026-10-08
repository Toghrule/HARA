using FluentValidation;

namespace Hara.Application.Faq.Commands.CreateFaqItem;

public class CreateFaqItemCommandValidator : AbstractValidator<CreateFaqItemCommand>
{
    public CreateFaqItemCommandValidator()
    {
        RuleFor(c => c.Question).NotEmpty().MaximumLength(500);
        RuleFor(c => c.Answer).NotEmpty().MaximumLength(4000);
        RuleFor(c => c.QuestionRu).MaximumLength(500);
        RuleFor(c => c.QuestionEn).MaximumLength(500);
        RuleFor(c => c.AnswerRu).MaximumLength(4000);
        RuleFor(c => c.AnswerEn).MaximumLength(4000);
    }
}
