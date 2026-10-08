using Hara.Domain.Restaurants;

namespace Hara.Application.Restaurants.Submissions;

/// <summary>
/// Read model for a <see cref="RestaurantSubmission"/>, returned by every Submissions query/command.
/// <c>HasOwnerAccount</c> is true when an owner signed up with the registration, so creating its restaurant
/// also activates that owner; <c>RestaurantId</c> is the restaurant created from it, once there is one.
/// </summary>
public sealed record RestaurantSubmissionDto(
    Guid Id,
    string RestaurantName,
    string? Description,
    string? Address,
    string? PhoneNumber,
    string SubmitterName,
    string? SubmitterEmail,
    string? SubmitterPhoneNumber,
    SubmissionStatus Status,
    string? AdminNote,
    DateTimeOffset? ReviewedAt,
    DateTimeOffset CreatedAt,
    bool HasOwnerAccount = false,
    Guid? RestaurantId = null)
{
    public static RestaurantSubmissionDto FromEntity(RestaurantSubmission submission) => new(
        submission.Id,
        submission.RestaurantName,
        submission.Description,
        submission.Address,
        submission.PhoneNumber,
        submission.SubmitterName,
        submission.SubmitterEmail,
        submission.SubmitterPhoneNumber,
        submission.Status,
        submission.AdminNote,
        submission.ReviewedAt,
        submission.CreatedAt,
        submission.OwnerUserId is not null,
        submission.RestaurantId);
}
