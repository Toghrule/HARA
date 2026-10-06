using FluentValidation;

namespace Hara.Application.Reservations.Commands.CreateReservation;

public class CreateReservationCommandValidator : AbstractValidator<CreateReservationCommand>
{
    public CreateReservationCommandValidator()
    {
        RuleFor(c => c.RestaurantId).NotEmpty();
        RuleFor(c => c.PhoneNumber)
            .Cascade(CascadeMode.Stop)
            .NotEmpty()
            .MaximumLength(50)
            .Matches(@"^\+?[0-9\s\-()]{7,20}$").WithMessage("'Phone Number' must be a valid phone number.")
            .Must(Common.PhoneNumber.HasValidDigitCount)
            .WithMessage($"'Phone Number' must have between {Common.PhoneNumber.MinDigits} and {Common.PhoneNumber.MaxDigits} digits.");
        RuleFor(c => c.DurationMinutes)
            .Must(minutes => minutes is 30 or 60).WithMessage("'Duration Minutes' must be 30 or 60.");
    }
}
