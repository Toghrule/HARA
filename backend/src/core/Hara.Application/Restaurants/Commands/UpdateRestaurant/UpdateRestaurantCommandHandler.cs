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
        restaurant.DescriptionRu = request.DescriptionRu;
        restaurant.DescriptionEn = request.DescriptionEn;
        restaurant.Address = request.Address;
        restaurant.Latitude = request.Latitude;
        restaurant.Longitude = request.Longitude;
        restaurant.PhoneNumber = request.PhoneNumber;
        restaurant.ImageUrl = request.ImageUrl;
        restaurant.DiscountPercent = request.DiscountPercent;
        restaurant.IsActive = request.IsActive;
        if (request.Cuisines is not null)
        {
            restaurant.Cuisines = request.Cuisines.Distinct().ToList();
        }

        if (request.GalleryUrls is not null)
        {
            restaurant.GalleryUrls = request.GalleryUrls.ToList();
        }

        repository.Update(restaurant);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return RestaurantDto.FromEntity(restaurant);
    }
}
