using FluentValidation;
using Hara.Application.Restaurants;

namespace Hara.Application.Venue.Commands.UpdateOpeningHours;

public class UpdateOpeningHoursCommandValidator : AbstractValidator<UpdateOpeningHoursCommand>
{
    /// <summary>The longest "stop taking requests" lead time an owner can choose, in minutes.</summary>
    public const int MaxLastRequestMinutes = 180;

    public UpdateOpeningHoursCommandValidator()
    {
        RuleFor(c => c.LastRequestMinutesBeforeClose).InclusiveBetween(0, MaxLastRequestMinutes);

        RuleFor(c => c.Days)
            .NotNull()
            .Must(days => days.Count == 0 || (days.Count == 7 && days.Select(d => d.Day).Distinct().Count() == 7))
            .WithMessage("Give all seven weekdays, once each, or none to remove the hours.");

        RuleForEach(c => c.Days).ChildRules(day =>
        {
            day.RuleFor(d => d.Day).IsInEnum();
            day.RuleFor(d => d.Opens)
                .Must(time => OpeningTime.Parse(time) is not null)
                .When(d => !d.IsClosed)
                .WithMessage("The opening time must be a time of day like 09:30.");
            day.RuleFor(d => d.Closes)
                .Must(time => OpeningTime.Parse(time) is not null)
                .When(d => !d.IsClosed)
                .WithMessage("The closing time must be a time of day like 23:00.");
        });
    }
}
