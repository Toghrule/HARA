using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Application.Venue;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.ChangeRequests.Commands.CreateChangeRequest;

public class CreateChangeRequestCommandHandler(VenueAccess access, IUnitOfWork unitOfWork, ICurrentUserService currentUser)
    : IRequestHandler<CreateChangeRequestCommand, ChangeRequestDto>
{
    /// <summary>How many requests one restaurant can have waiting for the admin at once.</summary>
    private const int MaxPendingPerRestaurant = 5;

    public async Task<ChangeRequestDto> Handle(CreateChangeRequestCommand request, CancellationToken cancellationToken)
    {
        // Always for the owner's own restaurant: the restaurant is never taken from the request.
        var owner = await access.RequireApprovedOwnerAsync(cancellationToken);

        var repository = unitOfWork.Repository<RestaurantChangeRequest>();
        var pending = await repository.Query()
            .CountAsync(c => c.RestaurantId == owner.RestaurantId && c.Status == ChangeRequestStatus.Pending, cancellationToken);
        if (pending >= MaxPendingPerRestaurant)
        {
            throw new ValidationException("changes", "You already have several requests waiting for review. Please wait for an answer first.");
        }

        var changeRequest = new RestaurantChangeRequest
        {
            RestaurantId = owner.RestaurantId,
            Restaurant = owner.Restaurant,
            RequestedByUserId = currentUser.UserId,
            Name = request.Name?.Trim(),
            Address = request.Address?.Trim(),
            PhoneNumber = request.PhoneNumber?.Trim(),
            Description = request.Description?.Trim(),
            DescriptionRu = request.DescriptionRu?.Trim(),
            DescriptionEn = request.DescriptionEn?.Trim(),
            DiscountPercent = request.DiscountPercent,
            OwnerNote = string.IsNullOrWhiteSpace(request.OwnerNote) ? null : request.OwnerNote.Trim(),
        };

        await repository.AddAsync(changeRequest, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return ChangeRequestDto.FromEntity(changeRequest);
    }
}
