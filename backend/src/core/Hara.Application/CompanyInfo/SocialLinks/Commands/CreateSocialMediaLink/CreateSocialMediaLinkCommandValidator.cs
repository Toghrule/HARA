using FluentValidation;

namespace Hara.Application.CompanyInfo.SocialLinks.Commands.CreateSocialMediaLink;

public class CreateSocialMediaLinkCommandValidator : AbstractValidator<CreateSocialMediaLinkCommand>
{
    public CreateSocialMediaLinkCommandValidator()
    {
        RuleFor(c => c.Platform).IsInEnum();
        RuleFor(c => c.Url).NotEmpty().MaximumLength(1000);
    }
}
