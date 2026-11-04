using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Reservations;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Reservations.Queries.GetReservationStatus;

public class GetReservationStatusQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetReservationStatusQuery, ReservationStatusDto>
{
    public async Task<ReservationStatusDto> Handle(GetReservationStatusQuery request, CancellationToken cancellationToken)
    {
        var code = request.Code.Trim().ToUpperInvariant();
        var reservation = await unitOfWork.Repository<Reservation>().Query()
            .FirstOrDefaultAsync(r => r.Code == code, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), code);

        // Whether this phone number already rated the restaurant, so the app does not offer the stars again.
        var rating = reservation.Status == ReservationStatus.Redeemed
            ? await unitOfWork.Repository<RestaurantRating>().Query()
                .Where(r => r.RestaurantId == reservation.RestaurantId && r.PhoneNumber == reservation.PhoneNumber)
                .Select(r => (int?)r.Stars)
                .FirstOrDefaultAsync(cancellationToken)
            : null;

        return ReservationStatusDto.FromEntity(reservation, DateTimeOffset.UtcNow, rating);
    }
}
