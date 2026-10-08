using FluentValidation;

namespace Hara.Application.Auth.Commands.RegisterOwner;

public class RegisterOwnerCommandValidator : AbstractValidator<RegisterOwnerCommand>
{
    public RegisterOwnerCommandValidator()
    {
        RuleFor(c => c.Email).NotEmpty().EmailAddress().MaximumLength(320);
        RuleFor(c => c.Password).NotEmpty().MaximumLength(100);
        RuleFor(c => c.FullName).NotEmpty().MaximumLength(200);
        RuleFor(c => c.PhoneNumber).MaximumLength(50);
        RuleFor(c => c.RestaurantName).NotEmpty().MaximumLength(200);
        RuleFor(c => c.Address).NotEmpty().MaximumLength(400);
        RuleFor(c => c.RestaurantPhoneNumber).MaximumLength(50);
        RuleFor(c => c.Description).MaximumLength(4000);
    }
}
