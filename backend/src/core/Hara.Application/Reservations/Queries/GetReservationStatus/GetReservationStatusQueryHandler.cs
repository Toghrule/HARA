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

        return ReservationStatusDto.FromEntity(reservation, DateTimeOffset.UtcNow);
    }
}
