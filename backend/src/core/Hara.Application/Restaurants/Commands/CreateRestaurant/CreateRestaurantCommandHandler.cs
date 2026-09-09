using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Application.Restaurants.Commands.CreateRestaurant;

public class CreateRestaurantCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<CreateRestaurantCommand, RestaurantDto>
{
    public async Task<RestaurantDto> Handle(CreateRestaurantCommand request, CancellationToken cancellationToken)
    {
        var restaurant = new Restaurant
        {
            Name = request.Name,
            Description = request.Description,
            Address = request.Address,
            PhoneNumber = request.PhoneNumber,
            ImageUrl = request.ImageUrl
        };

        await unitOfWork.Repository<Restaurant>().AddAsync(restaurant, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return RestaurantDto.FromEntity(restaurant);
    }
}
