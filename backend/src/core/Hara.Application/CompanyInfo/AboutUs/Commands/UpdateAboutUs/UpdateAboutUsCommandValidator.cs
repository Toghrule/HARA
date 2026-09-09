using FluentValidation;

namespace Hara.Application.CompanyInfo.AboutUs.Commands.UpdateAboutUs;

public class UpdateAboutUsCommandValidator : AbstractValidator<UpdateAboutUsCommand>
{
    public UpdateAboutUsCommandValidator()
    {
        RuleFor(c => c.CompanyName).NotEmpty().MaximumLength(200);
        RuleFor(c => c.Description).NotEmpty().MaximumLength(8000);
        RuleFor(c => c.LogoUrl).MaximumLength(1000);
    }
}
