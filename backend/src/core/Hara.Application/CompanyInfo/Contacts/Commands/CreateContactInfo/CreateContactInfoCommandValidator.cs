using FluentValidation;
using Hara.Domain.CompanyInfo;

namespace Hara.Application.CompanyInfo.Contacts.Commands.CreateContactInfo;

public class CreateContactInfoCommandValidator : AbstractValidator<CreateContactInfoCommand>
{
    public CreateContactInfoCommandValidator()
    {
        RuleFor(c => c.Type).IsInEnum();
        RuleFor(c => c.Value).NotEmpty().MaximumLength(320);
        RuleFor(c => c.Value).EmailAddress().When(c => c.Type == ContactType.Email);
        RuleFor(c => c.Label).MaximumLength(100);
    }
}
