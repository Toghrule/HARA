using FluentValidation;

namespace Hara.Application.Advertisements.Commands.ReorderAdvertisements;

public class ReorderAdvertisementCommandValidator : AbstractValidator<ReorderAdvertisementCommand>
{
    public ReorderAdvertisementCommandValidator()
    {
        RuleFor(c => c.OrderedIds).NotEmpty();
    }
}
