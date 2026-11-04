using FluentValidation;

namespace Hara.Application.Restaurants.Commands.CreateRestaurantOwner;

public class CreateRestaurantOwnerCommandValidator : AbstractValidator<CreateRestaurantOwnerCommand>
{
    public CreateRestaurantOwnerCommandValidator()
    {
        RuleFor(c => c.RestaurantId).NotEmpty();
        RuleFor(c => c.Email).NotEmpty().EmailAddress().MaximumLength(320);
        RuleFor(c => c.Password).NotEmpty().MaximumLength(100);
        RuleFor(c => c.FullName).NotEmpty().MaximumLength(200);
        RuleFor(c => c.PhoneNumber).MaximumLength(50);
    }
}
