using MediatR;

namespace Hara.Application.Venue.Commands.RespondToReservation;

/// <summary>
/// The restaurant's owner or a waiter answers a customer's request: accepting it starts the hold timer (and
/// shows the customer their code); declining ends it. Only requests to the signed-in person's own restaurant
/// can be answered, and only while they are still waiting.
/// </summary>
/// <param name="Code">The request's code; matched case-insensitively.</param>
/// <param name="Accept"><c>true</c> to accept, <c>false</c> to decline.</param>
public sealed record RespondToReservationCommand(string Code, bool Accept) : IRequest<VenueReservationDto>;
