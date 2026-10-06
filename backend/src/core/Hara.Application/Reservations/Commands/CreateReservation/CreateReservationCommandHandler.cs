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

    public async Task<ReservationDto> Handle(CreateReservationCommand request, CancellationToken cancellationToken)
    {
        var restaurant = await unitOfWork.Repository<Restaurant>().GetByIdAsync(request.RestaurantId, cancellationToken);

        if (restaurant is null || !restaurant.IsActive)
        {
            throw new NotFoundException(nameof(Restaurant), request.RestaurantId);
        }

        var repository = unitOfWork.Repository<Reservation>();
        var code = await GenerateUniqueCodeAsync(repository, cancellationToken);
        var now = DateTimeOffset.UtcNow;

        var reservation = new Reservation
        {
            RestaurantId = restaurant.Id,
            Restaurant = restaurant,
            PhoneNumber = request.PhoneNumber.Trim(),
            DurationMinutes = request.DurationMinutes,
            Code = code,
            ExpiresAt = now.AddMinutes(request.DurationMinutes)
        };

        await repository.AddAsync(reservation, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return ReservationDto.FromEntity(reservation, now);
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
