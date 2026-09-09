using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Restaurants.Queries.GetRestaurants;

public class GetRestaurantsQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetRestaurantsQuery, IReadOnlyList<RestaurantDto>>
{
    public async Task<IReadOnlyList<RestaurantDto>> Handle(GetRestaurantsQuery request, CancellationToken cancellationToken)
    {
        var query = unitOfWork.Repository<Restaurant>().Query();

        if (request.OnlyActive)
        {
            query = query.Where(r => r.IsActive);
        }

        var restaurants = await query.OrderBy(r => r.Name).ToListAsync(cancellationToken);

        return restaurants.Select(RestaurantDto.FromEntity).ToList();
    }
}
