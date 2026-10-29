using MediatR;

namespace Hara.Application.Statistics.Queries.GetRestaurantStats;

/// <summary>Every restaurant's numbers for the admin panel.</summary>
public sealed record GetRestaurantStatsQuery : IRequest<IReadOnlyList<RestaurantStatsDto>>;

/// <summary>Counts of the requests made in one stretch of time (by when the customer sent them).</summary>
/// <param name="Requests">All requests the customers sent.</param>
/// <param name="Accepted">Requests the restaurant accepted.</param>
/// <param name="Declined">Requests the restaurant declined.</param>
/// <param name="Unanswered">Requests nobody answered within the time allowed.</param>
/// <param name="Redeemed">Codes confirmed at the restaurant (the customer came and got the discount).</param>
/// <param name="NoShows">Accepted reservations whose hold time ran out without the code being confirmed.</param>
public sealed record StatsPeriodDto(int Requests, int Accepted, int Declined, int Unanswered, int Redeemed, int NoShows)
{
    public static StatsPeriodDto Empty { get; } = new(0, 0, 0, 0, 0, 0);
}

public sealed record RestaurantStatsDto(
    Guid RestaurantId,
    string RestaurantName,
    StatsPeriodDto ThisMonth,
    StatsPeriodDto LastMonth,
    StatsPeriodDto AllTime);
