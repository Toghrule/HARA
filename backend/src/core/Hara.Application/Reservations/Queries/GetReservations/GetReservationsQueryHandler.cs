using Hara.Application.Common.Interfaces;
using Hara.Domain.Reservations;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Reservations.Queries.GetReservations;

public class GetReservationsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetReservationsQuery, IReadOnlyList<ReservationDto>>
{
    private const int MaxResults = 200;

    public async Task<IReadOnlyList<ReservationDto>> Handle(GetReservationsQuery request, CancellationToken cancellationToken)
    {
        var now = DateTimeOffset.UtcNow;
        var query = unitOfWork.Repository<Reservation>().Query().Include(r => r.Restaurant).AsQueryable();

        var code = request.Code?.Trim().ToUpperInvariant();
        if (!string.IsNullOrEmpty(code))
        {
            query = query.Where(r => r.Code.Contains(code));
        }

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

        return reservations.Select(r => ReservationDto.FromEntity(r, now)).ToList();
    }
}
