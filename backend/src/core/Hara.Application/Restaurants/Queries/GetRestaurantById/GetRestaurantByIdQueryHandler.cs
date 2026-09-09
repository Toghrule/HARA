using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Application.Restaurants.Queries.GetRestaurantById;

public class GetRestaurantByIdQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetRestaurantByIdQuery, RestaurantDto>
{
    public async Task<RestaurantDto> Handle(GetRestaurantByIdQuery request, CancellationToken cancellationToken)
    {
        var restaurant = await unitOfWork.Repository<Restaurant>().GetByIdAsync(request.Id, cancellationToken);

        if (restaurant is null || (request.OnlyActive && !restaurant.IsActive))
        {
            throw new NotFoundException(nameof(Restaurant), request.Id);
        }

        return RestaurantDto.FromEntity(restaurant);
    }
}
