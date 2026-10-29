using Hara.Application.Common.Interfaces;
using Hara.Application.Statistics;
using Hara.Domain.Members;
using Hara.Domain.Reservations;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Venue.Queries.GetVenueStats;

public class GetVenueStatsQueryHandler(VenueAccess access, IUnitOfWork unitOfWork, ICurrentUserService currentUser)
    : IRequestHandler<GetVenueStatsQuery, VenueStatsDto>
{
    public async Task<VenueStatsDto> Handle(GetVenueStatsQuery request, CancellationToken cancellationToken)
    {
        var member = await access.RequireApprovedMemberAsync(cancellationToken);
        var now = DateTimeOffset.UtcNow;
        var startOfDay = BakuTime.StartOfDay(now);
        var startOfMonth = BakuTime.StartOfMonth(now);
        var startOfYear = BakuTime.StartOfYear(now);

        var restaurantReservations = unitOfWork.Repository<Reservation>().Query()
            .Where(r => r.RestaurantId == member.RestaurantId);

        var redeemedByMeToday = await restaurantReservations.CountAsync(
            r => r.Status == ReservationStatus.Redeemed && r.RedeemedByUserId == currentUser.UserId && r.RedeemedAt >= startOfDay,
            cancellationToken);

        if (member.Role != MemberRole.Owner)
        {
            return new VenueStatsDto(null, null, null, redeemedByMeToday);
        }

        // One restaurant's reservations since the start of the year: small enough to count here rather than in several queries.
        var rows = await restaurantReservations
            .Where(r => r.RespondedAt >= startOfYear || r.RedeemedAt >= startOfYear)
            .Select(r => new { r.Status, r.RespondedAt, r.RedeemedAt })
            .ToListAsync(cancellationToken);

        PeriodCountsDto Count(DateTimeOffset from) => new(
            rows.Count(r => r.Status != ReservationStatus.Declined && r.RespondedAt >= from),
            rows.Count(r => r.Status == ReservationStatus.Redeemed && r.RedeemedAt >= from));

        return new VenueStatsDto(Count(startOfDay), Count(startOfMonth), Count(startOfYear), redeemedByMeToday);
    }
}
