using Hara.Application.Common.Interfaces;
using Hara.Domain.Reservations;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Venue.Queries.GetVenueReservations;

public class GetVenueReservationsQueryHandler(VenueAccess access, IUnitOfWork unitOfWork)
    : IRequestHandler<GetVenueReservationsQuery, IReadOnlyList<VenueReservationDto>>
{
    private const int MaxResults = 100;

    public async Task<IReadOnlyList<VenueReservationDto>> Handle(GetVenueReservationsQuery request, CancellationToken cancellationToken)
    {
        var member = await access.RequireApprovedMemberAsync(cancellationToken);
        var now = DateTimeOffset.UtcNow;

        var query = unitOfWork.Repository<Reservation>().Query().Where(r => r.RestaurantId == member.RestaurantId);

        // "Expired" and "Active" are both stored as Active; the window decides which one a row is.
        query = request.Status switch
        {
            ReservationStatus.Active => query.Where(r => r.Status == ReservationStatus.Active && r.ExpiresAt > now),
            ReservationStatus.Expired => query.Where(r => r.Status == ReservationStatus.Active && r.ExpiresAt <= now),
            ReservationStatus.Redeemed => query.Where(r => r.Status == ReservationStatus.Redeemed),
            ReservationStatus.Cancelled => query.Where(r => r.Status == ReservationStatus.Cancelled),
            _ => query
        };

        var reservations = await query
            .OrderByDescending(r => r.CreatedAt)
            .Take(MaxResults)
            .ToListAsync(cancellationToken);

        return reservations
            .Select(r => VenueReservationDto.FromEntity(r, member.Restaurant!.DiscountPercent, now))
            .ToList();
    }
}
