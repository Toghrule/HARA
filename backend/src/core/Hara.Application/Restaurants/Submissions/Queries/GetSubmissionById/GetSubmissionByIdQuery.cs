using MediatR;

namespace Hara.Application.Restaurants.Submissions.Queries.GetSubmissionById;

/// <summary>Admin query to fetch a single submission's full detail.</summary>
public sealed record GetSubmissionByIdQuery(Guid Id) : IRequest<RestaurantSubmissionDto>;
