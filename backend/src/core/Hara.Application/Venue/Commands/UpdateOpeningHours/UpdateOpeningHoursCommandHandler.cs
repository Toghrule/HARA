using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Application.Restaurants;
using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Application.Venue.Commands.UpdateOpeningHours;

public class UpdateOpeningHoursCommandHandler(VenueAccess access, IUnitOfWork unitOfWork)
    : IRequestHandler<UpdateOpeningHoursCommand, VenueRestaurantDto>
{
    public async Task<VenueRestaurantDto> Handle(UpdateOpeningHoursCommand request, CancellationToken cancellationToken)
    {
        var owner = await access.RequireApprovedOwnerAsync(cancellationToken);

        var repository = unitOfWork.Repository<Restaurant>();
        var restaurant = await repository.GetByIdAsync(owner.RestaurantId, cancellationToken)
            ?? throw new NotFoundException(nameof(Restaurant), owner.RestaurantId);

        restaurant.OpeningHours = request.Days
            .Select(day => new DayHours
            {
                Day = day.Day,
                IsClosed = day.IsClosed,
                OpensAtMinute = day.IsClosed ? 0 : OpeningTime.Parse(day.Opens)!.Value,
                ClosesAtMinute = day.IsClosed ? 0 : OpeningTime.Parse(day.Closes)!.Value
            })
            .ToList();
        restaurant.LastRequestMinutesBeforeClose = request.LastRequestMinutesBeforeClose;

        repository.Update(restaurant);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return VenueRestaurantDto.FromEntity(restaurant);
    }
}
