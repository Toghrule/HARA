using FluentValidation;

namespace Hara.Application.Venue.Commands.RespondToReservation;

public class RespondToReservationCommandValidator : AbstractValidator<RespondToReservationCommand>
{
    public RespondToReservationCommandValidator()
    {
        RuleFor(c => c.Code).NotEmpty().MaximumLength(16);
    }
}
