using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Application.Restaurants.Submissions.Queries.GetSubmissions;

/// <summary>Admin query listing submissions, newest first, optionally filtered to one <see cref="SubmissionStatus"/> (e.g. the review queue shows only <see cref="SubmissionStatus.Pending"/>).</summary>
public sealed record GetSubmissionsQuery(SubmissionStatus? Status) : IRequest<IReadOnlyList<RestaurantSubmissionDto>>;
