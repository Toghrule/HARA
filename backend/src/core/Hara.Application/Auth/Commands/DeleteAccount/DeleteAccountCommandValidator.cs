using FluentValidation;

namespace Hara.Application.Auth.Commands.DeleteAccount;

public class DeleteAccountCommandValidator : AbstractValidator<DeleteAccountCommand>
{
    public DeleteAccountCommandValidator()
    {
        RuleFor(c => c.Password).NotEmpty().MaximumLength(100);
    }
}
