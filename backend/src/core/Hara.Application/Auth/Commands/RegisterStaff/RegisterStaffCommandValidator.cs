using FluentValidation;

namespace Hara.Application.Auth.Commands.RegisterStaff;

public class RegisterStaffCommandValidator : AbstractValidator<RegisterStaffCommand>
{
    public RegisterStaffCommandValidator()
    {
        RuleFor(c => c.Email).NotEmpty().EmailAddress().MaximumLength(320);
        RuleFor(c => c.Password).NotEmpty().MaximumLength(100);
        RuleFor(c => c.FullName).NotEmpty().MaximumLength(200);
        RuleFor(c => c.PhoneNumber).MaximumLength(50);
        RuleFor(c => c.RestaurantId).NotEmpty();
    }
}
