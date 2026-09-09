using FluentValidation;

namespace Hara.Application.CompanyInfo.SocialLinks.Commands.UpdateSocialMediaLink;

public class UpdateSocialMediaLinkCommandValidator : AbstractValidator<UpdateSocialMediaLinkCommand>
{
    public UpdateSocialMediaLinkCommandValidator()
    {
        RuleFor(c => c.Id).NotEmpty();
        RuleFor(c => c.Platform).IsInEnum();
        RuleFor(c => c.Url).NotEmpty().MaximumLength(1000);
    }
}
