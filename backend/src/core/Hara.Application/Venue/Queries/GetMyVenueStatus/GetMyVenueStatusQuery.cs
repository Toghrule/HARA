using MediatR;

namespace Hara.Application.Venue.Queries.GetMyVenueStatus;

/// <summary>
/// Where the signed-in owner or waiter stands — waiting for approval, approved for a restaurant, declined —
/// so the app knows which screen to show. Works for people who are not approved yet.
/// </summary>
public sealed record GetMyVenueStatusQuery : IRequest<VenueMeDto>;
