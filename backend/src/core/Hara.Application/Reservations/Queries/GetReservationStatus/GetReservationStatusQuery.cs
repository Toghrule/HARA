using MediatR;

namespace Hara.Application.Reservations.Queries.GetReservationStatus;

/// <summary>
/// Public query: lets the customer's app check whether a reservation code is still usable (the venue may
/// have redeemed it, or it may have been cancelled). The code itself is the proof of ownership.
/// </summary>
/// <param name="Code">The reservation code the customer was given; matched case-insensitively.</param>
public sealed record GetReservationStatusQuery(string Code) : IRequest<ReservationStatusDto>;
