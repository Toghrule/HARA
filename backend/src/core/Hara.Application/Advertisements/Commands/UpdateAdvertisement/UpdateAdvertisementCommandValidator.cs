using FluentValidation;

namespace Hara.Application.Advertisements.Commands.UpdateAdvertisement;

public class UpdateAdvertisementCommandValidator : AbstractValidator<UpdateAdvertisementCommand>
{
    public UpdateAdvertisementCommandValidator()
    {
        RuleFor(c => c.Id).NotEmpty();
        RuleFor(c => c.ImageUrl).NotEmpty().MaximumLength(1000);
        RuleFor(c => c.Title).MaximumLength(200);
        RuleFor(c => c.LinkUrl).MaximumLength(1000);
    }
}
