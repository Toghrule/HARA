using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Reservations;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Reservations.Commands.RedeemReservation;

public class RedeemReservationCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<RedeemReservationCommand, ReservationDto>
{
    public async Task<ReservationDto> Handle(RedeemReservationCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<Reservation>();
        var reservation = await repository.Query()
            .Include(r => r.Restaurant)
            .FirstOrDefaultAsync(r => r.Id == request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), request.Id);

        var now = DateTimeOffset.UtcNow;

        var problem = reservation.EffectiveStatus(now) switch
        {
            ReservationStatus.Redeemed => "This reservation code has already been redeemed.",
            ReservationStatus.Cancelled => "This reservation was cancelled.",
            ReservationStatus.Expired => "This reservation has expired.",
            _ => null
        };

        if (problem is not null)
        {
            var exception = new ValidationException();
            exception.Errors["code"] = [problem];
            throw exception;
        }

        reservation.Status = ReservationStatus.Redeemed;
        reservation.RedeemedAt = now;

        repository.Update(reservation);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return ReservationDto.FromEntity(reservation, now);
    }
}
