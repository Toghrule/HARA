using MediatR;

namespace Hara.Application.Restaurants.Commands.CreateRestaurantOwner;

/// <summary>
/// Admin command: gives a restaurant that has no owner yet (one the admin created without a sign-up) an owner account,
/// with an email and a password the admin then hands over. The account needs no emailed code (the admin knows the person);
/// the owner is asked to accept the terms of use and the restaurant agreement the first time they sign in.
/// </summary>
/// <param name="RestaurantId">The restaurant the owner will run.</param>
/// <param name="Email">Sign-in email.</param>
/// <param name="Password">Sign-in password (8+ characters with a lowercase letter and a digit).</param>
/// <param name="FullName">The owner's name.</param>
/// <param name="PhoneNumber">The owner's phone number, optional.</param>
public sealed record CreateRestaurantOwnerCommand(Guid RestaurantId, string Email, string Password, string FullName, string? PhoneNumber) : IRequest<Unit>;
