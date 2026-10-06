using MediatR;

namespace Hara.Application.Reservations.Commands.RedeemReservation;

/// <summary>Admin command: mark a reservation's code as used because the customer showed up in time.</summary>
/// <param name="Id">The reservation to redeem.</param>
public sealed record RedeemReservationCommand(Guid Id) : IRequest<ReservationDto>;
