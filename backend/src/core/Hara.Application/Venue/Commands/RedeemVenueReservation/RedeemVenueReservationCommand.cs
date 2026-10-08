using MediatR;

namespace Hara.Application.Venue.Commands.RedeemVenueReservation;

/// <summary>
/// The owner or waiter confirms the code a customer is showing: the customer arrived in time and gets the
/// restaurant's discount. Only codes of the signed-in person's own restaurant can be confirmed.
/// </summary>
/// <param name="Code">The code the customer shows; matched case-insensitively.</param>
public sealed record RedeemVenueReservationCommand(string Code) : IRequest<VenueReservationDto>;
