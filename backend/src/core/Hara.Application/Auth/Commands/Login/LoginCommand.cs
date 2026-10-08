using MediatR;

namespace Hara.Application.Auth.Commands.Login;

/// <summary>Signs in with email and password. Accounts are created by the admin seeder (admin) or by registration (restaurant owners and staff).</summary>
public sealed record LoginCommand(string Email, string Password) : IRequest<LoginResult>;

/// <summary>Outcome of a sign-in, registration or token refresh.</summary>
/// <param name="Token">The signed JWT bearer token to send as <c>Authorization: Bearer &lt;token&gt;</c> on subsequent requests.</param>
/// <param name="ExpiresAtUtc">UTC expiry of <paramref name="Token"/>.</param>
/// <param name="RefreshToken">Trade this at <c>POST /api/auth/refresh</c> for a new <paramref name="Token"/> before or after it expires.</param>
/// <param name="Roles">The account's roles (e.g. <c>Owner</c>, <c>Staff</c>, <c>Admin</c>).</param>
public sealed record LoginResult(string Token, DateTimeOffset ExpiresAtUtc, string? RefreshToken = null, IReadOnlyList<string>? Roles = null);
