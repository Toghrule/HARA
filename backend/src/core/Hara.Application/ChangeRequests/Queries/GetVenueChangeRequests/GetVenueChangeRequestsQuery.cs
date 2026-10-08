using MediatR;

namespace Hara.Application.ChangeRequests.Queries.GetVenueChangeRequests;

/// <summary>The owner's own restaurant's change requests and what the admin answered, newest first.</summary>
public sealed record GetVenueChangeRequestsQuery : IRequest<IReadOnlyList<ChangeRequestDto>>;
