using Hara.Application.Auth.Commands.Login;
using MediatR;

namespace Hara.Application.Auth.Commands.RegisterOwner;

/// <summary>
/// A restaurant owner signs up from the app: an account plus the restaurant's details in one step. The
/// admin reviews it and, when they create the restaurant from it, the account becomes that restaurant's
/// owner. Until then the owner can sign in but can't do anything for a restaurant. Returns a signed-in
/// session so the app can show "waiting for approval" without asking for the password again.
/// </summary>
/// <param name="Email">Sign-in email.</param>
/// <param name="Password">Sign-in password (8+ characters with a lowercase letter and a digit).</param>
/// <param name="FullName">The owner's name.</param>
/// <param name="PhoneNumber">The owner's phone number, optional.</param>
/// <param name="RestaurantName">The restaurant's name.</param>
/// <param name="Address">The restaurant's address.</param>
/// <param name="RestaurantPhoneNumber">The restaurant's phone number, optional.</param>
/// <param name="Description">A few words about the restaurant, optional.</param>
public sealed record RegisterOwnerCommand(
    string Email,
    string Password,
    string FullName,
    string? PhoneNumber,
    string RestaurantName,
    string Address,
    string? RestaurantPhoneNumber,
    string? Description) : IRequest<LoginResult>;
