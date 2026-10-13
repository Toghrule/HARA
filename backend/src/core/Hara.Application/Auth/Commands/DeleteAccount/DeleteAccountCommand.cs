using MediatR;

namespace Hara.Application.Auth.Commands.DeleteAccount;

/// <summary>
/// A restaurant owner or waiter deletes their own account (the app stores require this). The password is
/// asked for again so a stolen access token can't delete it. The person's name, email and phone are removed;
/// the restaurant itself stays, since it is a public listing.
/// </summary>
/// <param name="Password">The account's current password.</param>
public sealed record DeleteAccountCommand(string Password) : IRequest;
