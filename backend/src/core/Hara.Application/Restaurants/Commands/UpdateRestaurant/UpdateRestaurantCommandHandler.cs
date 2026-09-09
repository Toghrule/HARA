using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Application.Restaurants.Commands.UpdateRestaurant;

public class UpdateRestaurantCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<UpdateRestaurantCommand, RestaurantDto>
{
    public async Task<RestaurantDto> Handle(UpdateRestaurantCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<Restaurant>();
        var restaurant = await repository.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(Restaurant), request.Id);

        restaurant.Name = request.Name;
        restaurant.Description = request.Description;
        restaurant.Address = request.Address;
        restaurant.PhoneNumber = request.PhoneNumber;
        restaurant.ImageUrl = request.ImageUrl;
        restaurant.IsActive = request.IsActive;

        repository.Update(restaurant);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return RestaurantDto.FromEntity(restaurant);
    }
}
