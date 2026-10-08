using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Members;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Restaurants.Commands.CreateRestaurant;

public class CreateRestaurantCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<CreateRestaurantCommand, RestaurantDto>
{
    public async Task<RestaurantDto> Handle(CreateRestaurantCommand request, CancellationToken cancellationToken)
    {
        var restaurant = new Restaurant
        {
            Name = request.Name,
            Description = request.Description,
            DescriptionRu = request.DescriptionRu,
            DescriptionEn = request.DescriptionEn,
            Address = request.Address,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            PhoneNumber = request.PhoneNumber,
            ImageUrl = request.ImageUrl,
            DiscountPercent = request.DiscountPercent
        };

        await unitOfWork.Repository<Restaurant>().AddAsync(restaurant, cancellationToken);

        if (request.FromSubmissionId is { } submissionId)
        {
            await LinkSubmissionAsync(submissionId, restaurant, cancellationToken);
        }

        // The restaurant, the submission's approval and the owner's membership are saved together.
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return RestaurantDto.FromEntity(restaurant);
    }

    /// <summary>Approves the registration this restaurant comes from and, if an owner signed up with it, makes them the owner.</summary>
    private async Task LinkSubmissionAsync(Guid submissionId, Restaurant restaurant, CancellationToken cancellationToken)
    {
        var submissions = unitOfWork.Repository<RestaurantSubmission>();
        var submission = await submissions.GetByIdAsync(submissionId, cancellationToken)
            ?? throw new NotFoundException(nameof(RestaurantSubmission), submissionId);

        if (submission.RestaurantId is not null)
        {
            throw new ValidationException("fromSubmissionId", "A restaurant has already been created from this registration.");
        }

        if (submission.OwnerUserId is { } ownerUserId)
        {
            var alreadyMember = await unitOfWork.Repository<RestaurantMember>().Query()
                .AnyAsync(m => m.UserId == ownerUserId, cancellationToken);
            if (alreadyMember)
            {
                throw new ValidationException("fromSubmissionId", "This owner already works at a restaurant.");
            }

            await unitOfWork.Repository<RestaurantMember>().AddAsync(
                new RestaurantMember
                {
                    UserId = ownerUserId,
                    Restaurant = restaurant,
                    Role = MemberRole.Owner,
                    Status = MemberStatus.Approved,
                    FullName = submission.SubmitterName,
                    Email = submission.SubmitterEmail ?? string.Empty,
                    PhoneNumber = submission.SubmitterPhoneNumber,
                },
                cancellationToken);
        }

        submission.Status = SubmissionStatus.Approved;
        submission.ReviewedAt = DateTimeOffset.UtcNow;
        submission.RestaurantId = restaurant.Id;
        submissions.Update(submission);
    }
}
