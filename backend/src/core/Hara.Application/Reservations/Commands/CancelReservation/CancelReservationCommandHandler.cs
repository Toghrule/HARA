using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Reservations;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Reservations.Commands.CancelReservation;

public class CancelReservationCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<CancelReservationCommand, ReservationDto>
{
    public async Task<ReservationDto> Handle(CancelReservationCommand request, CancellationToken cancellationToken)
    {
        var code = request.Code.Trim().ToUpperInvariant();
        var repository = unitOfWork.Repository<Reservation>();
        var reservation = await repository.Query()
            .Include(r => r.Restaurant)
            .FirstOrDefaultAsync(r => r.Code == code, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), code);

        var now = DateTimeOffset.UtcNow;

        switch (reservation.EffectiveStatus(now))
        {
            case ReservationStatus.Redeemed:
                throw new ValidationException("code", "This reservation has already been used.");
            case ReservationStatus.Expired:
                throw new ValidationException("code", "This reservation has already expired.");
            case ReservationStatus.Cancelled:
                // Cancelling twice (e.g. a retry after a dropped connection) is not an error.
                return ReservationDto.FromEntity(reservation, now);
        }

        reservation.Status = ReservationStatus.Cancelled;

        repository.Update(reservation);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return ReservationDto.FromEntity(reservation, now);
    }
}
