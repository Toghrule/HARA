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

        query = query.WithEffectiveStatus(request.Status, now);

        var reservations = await query
            .OrderByDescending(r => r.CreatedAt)
            .Take(MaxResults)
            .ToListAsync(cancellationToken);

        return reservations.Select(r => ReservationDto.FromEntity(r, now)).ToList();
    }
}
