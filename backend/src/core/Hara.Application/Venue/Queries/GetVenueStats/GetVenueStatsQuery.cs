using MediatR;

namespace Hara.Application.Venue.Queries.GetVenueStats;

/// <summary>The signed-in owner or waiter's numbers; see <see cref="VenueStatsDto"/>.</summary>
public sealed record GetVenueStatsQuery : IRequest<VenueStatsDto>;

/// <summary>Two counts for one stretch of time.</summary>
/// <param name="Accepted">Requests the restaurant accepted in that time.</param>
/// <param name="Redeemed">Codes confirmed at the restaurant in that time (the customer really came).</param>
public sealed record PeriodCountsDto(int Accepted, int Redeemed);

/// <summary>
/// What the app shows on the stats screen. The restaurant-wide counts are for the owner only (<c>null</c> for a waiter);
/// everyone gets how many codes they themselves confirmed today.
/// </summary>
public sealed record VenueStatsDto(
    PeriodCountsDto? Today,
    PeriodCountsDto? ThisMonth,
    PeriodCountsDto? ThisYear,
    int RedeemedByMeToday);
