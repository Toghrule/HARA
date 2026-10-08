using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Reservations;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Venue.Commands.RedeemVenueReservation;

public class RedeemVenueReservationCommandHandler(VenueAccess access, IUnitOfWork unitOfWork, ICurrentUserService currentUser)
    : IRequestHandler<RedeemVenueReservationCommand, VenueReservationDto>
{
    public async Task<VenueReservationDto> Handle(RedeemVenueReservationCommand request, CancellationToken cancellationToken)
    {
        var member = await access.RequireApprovedMemberAsync(cancellationToken);
        var code = request.Code.Trim().ToUpperInvariant();

        var repository = unitOfWork.Repository<Reservation>();

        // Looked up by restaurant as well as code: a code of another restaurant is "not found", not "forbidden",
        // so a waiter learns nothing about codes that aren't theirs.
        var reservation = await repository.Query()
            .FirstOrDefaultAsync(r => r.Code == code && r.RestaurantId == member.RestaurantId, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), code);

        var now = DateTimeOffset.UtcNow;

        var problem = reservation.EffectiveStatus(now) switch
        {
            ReservationStatus.Redeemed => "This code has already been used.",
            ReservationStatus.Cancelled => "The customer cancelled this reservation.",
            ReservationStatus.Expired => "This reservation has expired.",
            _ => null
        };

        if (problem is not null)
        {
            throw new ValidationException("code", problem);
        }

        reservation.Status = ReservationStatus.Redeemed;
        reservation.RedeemedAt = now;
        reservation.RedeemedByUserId = currentUser.UserId;

        repository.Update(reservation);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return VenueReservationDto.FromEntity(reservation, member.Restaurant!.DiscountPercent, now);
    }
}
