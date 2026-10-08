using MediatR;

namespace Hara.Application.Venue.Commands.RemoveStaff;

/// <summary>
/// The owner removes a waiter (or clears a declined request). The waiter's account is deleted too, so
/// they stop being able to sign in and the same email can sign up again later.
/// </summary>
/// <param name="MemberId">The waiter's membership.</param>
public sealed record RemoveStaffCommand(Guid MemberId) : IRequest;
