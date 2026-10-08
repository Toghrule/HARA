using MediatR;

namespace Hara.Application.Venue.Queries.GetVenueReservation;

/// <summary>
/// Looks up the code a customer is showing, so the waiter can check it before confirming. Only codes of
/// the signed-in person's own restaurant are found — a code of any other restaurant looks like a code
/// that doesn't exist.
/// </summary>
/// <param name="Code">The code the customer shows; matched case-insensitively.</param>
public sealed record GetVenueReservationQuery(string Code) : IRequest<VenueReservationDto>;
