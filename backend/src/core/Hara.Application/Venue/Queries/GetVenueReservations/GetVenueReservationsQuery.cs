using Hara.Domain.Reservations;
using MediatR;

namespace Hara.Application.Venue.Queries.GetVenueReservations;

/// <summary>The signed-in person's restaurant's reservations, newest first.</summary>
/// <param name="Status">Only reservations in this (effective) state; all of them when <c>null</c>.</param>
public sealed record GetVenueReservationsQuery(ReservationStatus? Status) : IRequest<IReadOnlyList<VenueReservationDto>>;
