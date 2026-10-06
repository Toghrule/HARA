using MediatR;

namespace Hara.Application.Reservations.Commands.CancelReservation;

/// <summary>
/// Public command: the customer gives up a reservation before using it (e.g. picked the wrong venue),
/// which frees their phone number to book again. The code itself is the proof of ownership.
/// </summary>
/// <param name="Code">The reservation code the customer was given; matched case-insensitively.</param>
public sealed record CancelReservationCommand(string Code) : IRequest<ReservationDto>;
