using MediatR;

namespace Hara.Application.Venue.Commands.ReviewStaff;

/// <summary>The owner approves or declines a waiter who asked to join their restaurant.</summary>
/// <param name="MemberId">The waiter's membership.</param>
/// <param name="Approve"><c>true</c> to approve, <c>false</c> to decline.</param>
public sealed record ReviewStaffCommand(Guid MemberId, bool Approve) : IRequest<StaffMemberDto>;
