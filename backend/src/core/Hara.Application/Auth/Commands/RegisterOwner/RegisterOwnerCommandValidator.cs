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
        // The apps send the version of each text the person ticked the box for; anything but the current one is refused.
        RuleFor(c => c.AcceptedTermsVersion).Equal(Domain.Members.LegalVersions.UserTerms).WithMessage("Please accept the terms of use.");
        RuleFor(c => c.AcceptedVenueAgreementVersion).Equal(Domain.Members.LegalVersions.VenueAgreement).WithMessage("Please accept the restaurant agreement.");
    }
}
