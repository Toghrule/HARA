using MediatR;

namespace Hara.Application.Restaurants.Submissions.Commands.CreateSubmission;

/// <summary>Public "add your restaurant" command, submitted anonymously from the mobile app.</summary>
public sealed record CreateSubmissionCommand(
    string RestaurantName,
    string? Description,
    string? Address,
    string? PhoneNumber,
    string SubmitterName,
    string? SubmitterEmail,
    string? SubmitterPhoneNumber) : IRequest<RestaurantSubmissionDto>;
