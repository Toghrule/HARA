using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Application.Restaurants.Commands.DeleteRestaurant;

public class DeleteRestaurantCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<DeleteRestaurantCommand>
{
    public async Task Handle(DeleteRestaurantCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<Restaurant>();
        var restaurant = await repository.GetByIdAsync(request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(Restaurant), request.Id);

        repository.Remove(restaurant);
        await unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
