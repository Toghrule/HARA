using Hara.Application.Common;
using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Reservations;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Reservations.Commands.CreateReservation;

public class CreateReservationCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<CreateReservationCommand, ReservationDto>
{
    private const int MaxCodeAttempts = 5;

    /// <summary>Caps how many reservations one phone number can make in a rolling 24 hours, whatever their state.</summary>
    private const int MaxReservationsPerPhonePerDay = 5;

    public async Task<ReservationDto> Handle(CreateReservationCommand request, CancellationToken cancellationToken)
    {
        var restaurant = await unitOfWork.Repository<Restaurant>().GetByIdAsync(request.RestaurantId, cancellationToken);

        if (restaurant is null || !restaurant.IsActive)
        {
            throw new NotFoundException(nameof(Restaurant), request.RestaurantId);
        }

        var repository = unitOfWork.Repository<Reservation>();
        var phoneNumber = PhoneNumber.Normalize(request.PhoneNumber);
        var now = DateTimeOffset.UtcNow;

        await EnsurePhoneMayReserveAsync(repository, phoneNumber, now, cancellationToken);

        var reservation = new Reservation
        {
            RestaurantId = restaurant.Id,
            Restaurant = restaurant,
            PhoneNumber = phoneNumber,
            DurationMinutes = request.DurationMinutes,
            Code = await GenerateUniqueCodeAsync(repository, cancellationToken),
            ExpiresAt = now.AddMinutes(request.DurationMinutes)
        };

        await repository.AddAsync(reservation, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return ReservationDto.FromEntity(reservation, now);
    }

    /// <summary>
    /// Phone numbers aren't verified, so these rules only blunt casual abuse (a script holding a venue's tables
    /// with phantom reservations); SMS verification is what would stop a determined attacker.
    /// </summary>
    private static async Task EnsurePhoneMayReserveAsync(
        IRepository<Reservation> repository,
        string phoneNumber,
        DateTimeOffset now,
        CancellationToken cancellationToken)
    {
        var hasLiveReservation = await repository.Query().AnyAsync(
            r => r.PhoneNumber == phoneNumber && r.Status == ReservationStatus.Active && r.ExpiresAt > now,
            cancellationToken);

        if (hasLiveReservation)
        {
            throw new ValidationException(
                "PhoneNumber",
                "This phone number already has an active reservation. Use its code, or wait until it expires to book another.");
        }

        var since = now.AddHours(-24);
        var recentCount = await repository.Query().CountAsync(
            r => r.PhoneNumber == phoneNumber && r.CreatedAt > since,
            cancellationToken);

        if (recentCount >= MaxReservationsPerPhonePerDay)
        {
            throw new ValidationException(
                "PhoneNumber",
                "This phone number has reached today's reservation limit. Please try again tomorrow.");
        }
    }

    private static async Task<string> GenerateUniqueCodeAsync(IRepository<Reservation> repository, CancellationToken cancellationToken)
    {
        for (var attempt = 0; attempt < MaxCodeAttempts; attempt++)
        {
            var code = ReservationCodeGenerator.Generate();

            if (!await repository.Query().AnyAsync(r => r.Code == code, cancellationToken))
            {
                return code;
            }
        }

        throw new InvalidOperationException("Could not generate a unique reservation code.");
    }
}
