using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Reservations;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Venue.Queries.GetVenueReservation;

public class GetVenueReservationQueryHandler(VenueAccess access, IUnitOfWork unitOfWork)
    : IRequestHandler<GetVenueReservationQuery, VenueReservationDto>
{
    public async Task<VenueReservationDto> Handle(GetVenueReservationQuery request, CancellationToken cancellationToken)
    {
        var member = await access.RequireApprovedMemberAsync(cancellationToken);
        var code = request.Code.Trim().ToUpperInvariant();

        var reservation = await unitOfWork.Repository<Reservation>().Query()
            .FirstOrDefaultAsync(r => r.Code == code && r.RestaurantId == member.RestaurantId, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), code);

        return VenueReservationDto.FromEntity(reservation, member.Restaurant!.DiscountPercent, DateTimeOffset.UtcNow);
    }
}
