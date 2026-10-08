using FluentValidation;

namespace Hara.Application.Venue.Commands.RedeemVenueReservation;

public class RedeemVenueReservationCommandValidator : AbstractValidator<RedeemVenueReservationCommand>
{
    public RedeemVenueReservationCommandValidator()
    {
        RuleFor(c => c.Code).NotEmpty().MaximumLength(16);
    }
}
