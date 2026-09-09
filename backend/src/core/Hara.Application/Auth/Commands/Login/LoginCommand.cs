using MediatR;

namespace Hara.Application.Auth.Commands.Login;

/// <summary>Admin login. There is no self-registration — only a seeded admin account (see <c>IdentitySeeder</c>) can authenticate.</summary>
public sealed record LoginCommand(string Email, string Password) : IRequest<LoginResult>;

/// <summary>Outcome of a <see cref="LoginCommand"/>.</summary>
/// <param name="Token">The signed JWT bearer token to send as <c>Authorization: Bearer &lt;token&gt;</c> on subsequent admin requests.</param>
/// <param name="ExpiresAtUtc">UTC expiry of <paramref name="Token"/>.</param>
public sealed record LoginResult(string Token, DateTimeOffset ExpiresAtUtc);
