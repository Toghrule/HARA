using Hara.Application.Common.Interfaces;
using Hara.Application.Reservations;
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

        var query = unitOfWork.Repository<Reservation>().Query()
            .Where(r => r.RestaurantId == member.RestaurantId)
            .WithEffectiveStatus(request.Status, now);

        // Requests waiting for an answer are worked through in the order they came in; everything else newest first.
        var ordered = request.Status == ReservationStatus.Pending
            ? query.OrderBy(r => r.CreatedAt)
            : query.OrderByDescending(r => r.CreatedAt);

        var reservations = await ordered.Take(MaxResults).ToListAsync(cancellationToken);

        return reservations
            .Select(r => VenueReservationDto.FromEntity(r, member.Restaurant!.DiscountPercent, now))
            .ToList();
    }
}
