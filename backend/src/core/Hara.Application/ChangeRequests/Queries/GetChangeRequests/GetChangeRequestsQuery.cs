using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Application.ChangeRequests.Queries.GetChangeRequests;

/// <summary>Admin list of owners' change requests, newest first.</summary>
/// <param name="Status">Only requests in this state; all of them when <c>null</c>.</param>
public sealed record GetChangeRequestsQuery(ChangeRequestStatus? Status) : IRequest<IReadOnlyList<ChangeRequestDto>>;
