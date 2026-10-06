using Hara.Domain.Reservations;
using MediatR;

namespace Hara.Application.Reservations.Queries.GetReservations;

/// <summary>Admin query: list reservations, newest first, optionally narrowed by code and/or state.</summary>
/// <param name="Code">Case-insensitive code (or part of one) to search for.</param>
/// <param name="Status">Only reservations in this effective state, including <see cref="ReservationStatus.Expired"/>.</param>
public sealed record GetReservationsQuery(string? Code = null, ReservationStatus? Status = null)
    : IRequest<IReadOnlyList<ReservationDto>>;
