using Hara.Application.Auth.Commands.Login;
using MediatR;

namespace Hara.Application.Auth.Commands.RegisterStaff;

/// <summary>
/// A waiter or cashier signs up for an existing restaurant. The restaurant's owner has to approve them
/// before they can confirm codes. Returns a signed-in session so the app can show "waiting for the
/// owner" without asking for the password again.
/// </summary>
/// <param name="Email">Sign-in email.</param>
/// <param name="Password">Sign-in password (8+ characters with a lowercase letter and a digit).</param>
/// <param name="FullName">The person's name, so the owner knows who is asking.</param>
/// <param name="PhoneNumber">The person's phone number, optional.</param>
/// <param name="RestaurantId">The restaurant they work at.</param>
public sealed record RegisterStaffCommand(
    string Email,
    string Password,
    string FullName,
    string? PhoneNumber,
    Guid RestaurantId) : IRequest<LoginResult>;
