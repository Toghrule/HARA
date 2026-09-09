using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Application.Restaurants.Submissions.Commands.ReviewSubmission;

/// <summary>
/// Admin command to accept or decline a pending <see cref="RestaurantSubmission"/>.
/// This only records the decision — approving does not automatically create a
/// <see cref="Domain.Restaurants.Restaurant"/>; the admin still creates one separately, informed by the submission.
/// </summary>
public sealed record ReviewSubmissionCommand(Guid Id, SubmissionStatus Decision, string? AdminNote) : IRequest<RestaurantSubmissionDto>;
