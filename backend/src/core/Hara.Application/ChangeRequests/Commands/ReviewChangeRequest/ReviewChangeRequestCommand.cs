using Hara.Domain.Restaurants;
using MediatR;

namespace Hara.Application.ChangeRequests.Commands.ReviewChangeRequest;

/// <summary>
/// Admin command to accept or decline a pending <see cref="RestaurantChangeRequest"/>. Approving applies the
/// requested changes to the restaurant in the same step; declining leaves the restaurant as it is.
/// </summary>
public sealed record ReviewChangeRequestCommand(Guid Id, ChangeRequestStatus Decision, string? AdminNote) : IRequest<ChangeRequestDto>;
