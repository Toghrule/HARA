using Hara.Application.Restaurants;
using MediatR;

namespace Hara.Application.Venue.Commands.UpdateOpeningHours;

/// <summary>
/// The owner sets when the restaurant is open. Takes effect at once, without the admin's approval: hours change
/// too often (holidays, closing early) to wait for it.
/// </summary>
/// <param name="Days">All seven weekdays, or empty to remove the hours (the restaurant is then always open).</param>
/// <param name="LastRequestMinutesBeforeClose">How long before closing time the restaurant stops taking table requests.</param>
public sealed record UpdateOpeningHoursCommand(IReadOnlyList<DayHoursDto> Days, int LastRequestMinutesBeforeClose)
    : IRequest<VenueRestaurantDto>;
