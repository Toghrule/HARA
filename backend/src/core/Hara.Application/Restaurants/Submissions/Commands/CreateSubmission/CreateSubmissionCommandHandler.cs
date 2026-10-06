using Hara.Application.Common;
using Hara.Application.Common.Exceptions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Restaurants;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace Hara.Application.Restaurants.Submissions.Commands.CreateSubmission;

public class CreateSubmissionCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<CreateSubmissionCommand, RestaurantSubmissionDto>
{
    /// <summary>How many requests from one contact can wait for review at once.</summary>
    private const int MaxPendingPerContact = 3;

    public async Task<RestaurantSubmissionDto> Handle(CreateSubmissionCommand request, CancellationToken cancellationToken)
    {
        var restaurantName = request.RestaurantName.Trim();
        var email = Clean(request.SubmitterEmail);
        var phone = Clean(request.SubmitterPhoneNumber) is { } rawPhone ? PhoneNumber.Normalize(rawPhone) : null;

        var repository = unitOfWork.Repository<RestaurantSubmission>();
        await EnsureContactMaySubmitAsync(repository, restaurantName, email, phone, cancellationToken);

        var submission = new RestaurantSubmission
        {
            RestaurantName = restaurantName,
            Description = Clean(request.Description),
            Address = Clean(request.Address),
            PhoneNumber = Clean(request.PhoneNumber),
            SubmitterName = request.SubmitterName.Trim(),
            SubmitterEmail = email,
            SubmitterPhoneNumber = phone,
            Status = SubmissionStatus.Pending
        };

        await repository.AddAsync(submission, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return RestaurantSubmissionDto.FromEntity(submission);
    }

    /// <summary>
    /// Submissions are reviewed by an admin anyway, so these rules just keep one contact from burying
    /// the queue: no duplicate request while one is pending, and a cap on pending requests.
    /// </summary>
    private static async Task EnsureContactMaySubmitAsync(
        IRepository<RestaurantSubmission> repository,
        string restaurantName,
        string? email,
        string? phone,
        CancellationToken cancellationToken)
    {
        var emailLower = email?.ToLowerInvariant();
        var nameLower = restaurantName.ToLowerInvariant();

        var pendingFromSameContact = repository.Query().Where(s =>
            s.Status == SubmissionStatus.Pending &&
            ((emailLower != null && s.SubmitterEmail != null && s.SubmitterEmail.ToLower() == emailLower) ||
             (phone != null && s.SubmitterPhoneNumber == phone)));

        if (await pendingFromSameContact.AnyAsync(s => s.RestaurantName.ToLower() == nameLower, cancellationToken))
        {
            throw new ValidationException(
                "RestaurantName",
                "We already have a pending request for this restaurant from you. We'll be in touch once we've reviewed it.");
        }

        if (await pendingFromSameContact.CountAsync(cancellationToken) >= MaxPendingPerContact)
        {
            throw new ValidationException(
                "SubmitterEmail",
                "You already have several requests waiting for review. Please wait until we've looked at them.");
        }
    }

    private static string? Clean(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
