using FluentValidation;
using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Reservations;
using MediatR;
using Microsoft.EntityFrameworkCore;
using ValidationException = Hara.Application.Common.Exceptions.ValidationException;

namespace Hara.Application.Reservations.Commands.RateReservation;

/// <summary>
/// Public command: the customer rates the restaurant after the restaurant confirmed their code (they were there). One
/// rating per phone number per restaurant, stars only. The code is the proof of ownership.
/// </summary>
/// <param name="Code">The reservation code; matched case-insensitively.</param>
/// <param name="Stars">From 1 to 5.</param>
public sealed record RateReservationCommand(string Code, int Stars) : IRequest<Unit>;

public class RateReservationCommandValidator : AbstractValidator<RateReservationCommand>
{
    public RateReservationCommandValidator()
    {
        RuleFor(c => c.Code).NotEmpty().MaximumLength(16);
        RuleFor(c => c.Stars).InclusiveBetween(RestaurantRating.MinStars, RestaurantRating.MaxStars);
    }
}

public class RateReservationCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<RateReservationCommand, Unit>
{
    public async Task<Unit> Handle(RateReservationCommand request, CancellationToken cancellationToken)
    {
        var code = request.Code.Trim().ToUpperInvariant();
        var reservation = await unitOfWork.Repository<Reservation>().Query()
            .Include(r => r.Restaurant)
            .FirstOrDefaultAsync(r => r.Code == code, cancellationToken)
            ?? throw new NotFoundException(nameof(Reservation), code);

        // Only a code the restaurant confirmed counts, so nobody rates a place they never went to.
        if (reservation.Status != ReservationStatus.Redeemed)
        {
            throw new ValidationException("code", "You can rate a restaurant after it has confirmed your code.");
        }

        var ratings = unitOfWork.Repository<RestaurantRating>();
        var already = await ratings.Query().AnyAsync(r => r.RestaurantId == reservation.RestaurantId && r.PhoneNumber == reservation.PhoneNumber, cancellationToken);
        if (already)
        {
            throw new ValidationException("stars", "You have already rated this restaurant.");
        }

        await ratings.AddAsync(new RestaurantRating { RestaurantId = reservation.RestaurantId, PhoneNumber = reservation.PhoneNumber, Stars = request.Stars }, cancellationToken);
        reservation.Restaurant!.RatingCount += 1;
        reservation.Restaurant.RatingTotal += request.Stars;

        try
        {
            await unitOfWork.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            // Two requests at once: the unique index let only one through.
            throw new ValidationException("stars", "You have already rated this restaurant.");
        }

        return Unit.Value;
    }
}
