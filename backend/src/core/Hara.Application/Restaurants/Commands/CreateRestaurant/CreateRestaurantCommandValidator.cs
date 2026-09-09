using FluentValidation;

namespace Hara.Application.Restaurants.Commands.CreateRestaurant;

public class CreateRestaurantCommandValidator : AbstractValidator<CreateRestaurantCommand>
{
    public CreateRestaurantCommandValidator()
    {
        RuleFor(c => c.Name).NotEmpty().MaximumLength(200);
        RuleFor(c => c.Address).NotEmpty().MaximumLength(400);
        RuleFor(c => c.PhoneNumber).MaximumLength(50);
        RuleFor(c => c.Description).MaximumLength(4000);
        RuleFor(c => c.ImageUrl).MaximumLength(1000);
    }
}
