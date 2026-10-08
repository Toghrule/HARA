using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.ChangeRequests.Commands.ReviewChangeRequest;

public class ReviewChangeRequestCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<ReviewChangeRequestCommand, ChangeRequestDto>
{
    public async Task<ChangeRequestDto> Handle(ReviewChangeRequestCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<RestaurantChangeRequest>();
        var changeRequest = await repository.Query()
            .Include(c => c.Restaurant)
            .FirstOrDefaultAsync(c => c.Id == request.Id, cancellationToken)
            ?? throw new NotFoundException(nameof(RestaurantChangeRequest), request.Id);

        if (changeRequest.Status != ChangeRequestStatus.Pending)
        {
            throw new ValidationException("id", "This request has already been reviewed.");
        }

        if (request.Decision == ChangeRequestStatus.Approved)
        {
            Apply(changeRequest, changeRequest.Restaurant!);
            unitOfWork.Repository<Restaurant>().Update(changeRequest.Restaurant!);
        }

        changeRequest.Status = request.Decision;
        changeRequest.AdminNote = string.IsNullOrWhiteSpace(request.AdminNote) ? null : request.AdminNote.Trim();
        changeRequest.ReviewedAt = DateTimeOffset.UtcNow;

        repository.Update(changeRequest);
        // The restaurant's new values and the decision are saved together.
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return ChangeRequestDto.FromEntity(changeRequest);
    }

    /// <summary>Copies the asked-for fields onto the restaurant; an empty optional text removes it.</summary>
    private static void Apply(RestaurantChangeRequest change, Restaurant restaurant)
    {
        if (change.Name is not null) restaurant.Name = change.Name;
        if (change.Address is not null) restaurant.Address = change.Address;
        if (change.PhoneNumber is not null) restaurant.PhoneNumber = Blank(change.PhoneNumber);
        if (change.Description is not null) restaurant.Description = Blank(change.Description);
        if (change.DescriptionRu is not null) restaurant.DescriptionRu = Blank(change.DescriptionRu);
        if (change.DescriptionEn is not null) restaurant.DescriptionEn = Blank(change.DescriptionEn);
        if (change.DiscountPercent is { } discount) restaurant.DiscountPercent = discount;
    }

    private static string? Blank(string value) => value.Length == 0 ? null : value;
}
