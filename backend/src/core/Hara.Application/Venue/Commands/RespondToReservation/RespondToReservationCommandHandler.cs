using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Application.Notifications;
using Hara.Domain.Reservations;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Venue.Commands.RespondToReservation;

public class RespondToReservationCommandHandler(VenueAccess access, IUnitOfWork unitOfWork, ICurrentUserService currentUser, ReservationNotifier notifier)
    : IRequestHandler<RespondToReservationCommand, VenueReservationDto>
{
    public async Task<VenueReservationDto> Handle(RespondToReservationCommand request, CancellationToken cancellationToken)
    {
        var member = await access.RequireApprovedMemberAsync(cancellationToken);
        var code = request.Code.Trim().ToUpperInvariant();
        var repository = unitOfWork.Repository<Reservation>();

        // Found by restaurant as well as code, so another restaurant's request is "not found", not "forbidden".
        var reservation = await repository.Query()
            .FirstOrDefaultAsync(r => r.Code == code && r.RestaurantId == member.RestaurantId, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), code);

        var now = DateTimeOffset.UtcNow;

        var problem = reservation.EffectiveStatus(now) switch
        {
            ReservationStatus.Pending => null,
            ReservationStatus.Active => "This request has already been accepted.",
            ReservationStatus.Declined => "This request has already been declined.",
            ReservationStatus.Cancelled => "The customer cancelled this request.",
            ReservationStatus.Redeemed => "This code has already been used.",
            _ => "This request is no longer waiting for an answer."
        };

        if (problem is not null)
        {
            throw new ValidationException("code", problem);
        }

        reservation.RespondedAt = now;
        reservation.RespondedByUserId = currentUser.UserId;

        if (request.Accept)
        {
            // The hold timer starts now, not when the customer sent the request.
            reservation.Status = ReservationStatus.Active;
            reservation.ExpiresAt = now.AddMinutes(Reservation.HoldMinutes);
        }
        else
        {
            reservation.Status = ReservationStatus.Declined;
        }

        repository.Update(reservation);
        await unitOfWork.SaveChangesAsync(cancellationToken);
        await notifier.AnsweredAsync(reservation, member.Restaurant!.Name, request.Accept);

        return VenueReservationDto.FromEntity(reservation, member.Restaurant!.DiscountPercent, now);
    }
}
