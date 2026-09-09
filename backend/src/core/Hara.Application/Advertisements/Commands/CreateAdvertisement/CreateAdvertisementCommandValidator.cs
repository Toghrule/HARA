using FluentValidation;

namespace Hara.Application.Advertisements.Commands.CreateAdvertisement;

public class CreateAdvertisementCommandValidator : AbstractValidator<CreateAdvertisementCommand>
{
    public CreateAdvertisementCommandValidator()
    {
        RuleFor(c => c.ImageUrl).NotEmpty().MaximumLength(1000);
        RuleFor(c => c.Title).MaximumLength(200);
        RuleFor(c => c.LinkUrl).MaximumLength(1000);
    }
}
