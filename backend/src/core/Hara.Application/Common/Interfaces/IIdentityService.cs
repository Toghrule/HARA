namespace Hara.Application.Common.Interfaces;

/// <summary>
/// Accounts and sessions: registers users, verifies credentials and issues access and refresh
/// tokens. Kept separate from <see cref="IRepository{T}"/>/<see cref="IUnitOfWork"/> because identity
/// (password hashing, sign-in checks, token issuance) isn't a domain entity CRUD concern — it's
/// wrapped around ASP.NET Core Identity instead.
/// </summary>
public interface IIdentityService
{
    /// <summary>
    /// Validates credentials and, on success, issues a short-lived JWT access token plus a long-lived
    /// refresh token the app can trade for a new access token.
    /// </summary>
    Task<AuthenticationResult> AuthenticateAsync(string email, string password, CancellationToken cancellationToken = default);

    /// <summary>
    /// Trades a refresh token for a new access token and a new refresh token. The old refresh token stops
    /// working, so a stolen copy that is used after the real app has refreshed fails.
    /// </summary>
    Task<AuthenticationResult> RefreshAsync(string refreshToken, CancellationToken cancellationToken = default);

    /// <summary>Ends a session by revoking its refresh token. Unknown or already revoked tokens are ignored.</summary>
    Task RevokeRefreshTokenAsync(string refreshToken, CancellationToken cancellationToken = default);

    /// <summary>Creates an account with the given role (creating the role first if it doesn't exist yet).</summary>
    Task<RegistrationResult> RegisterAsync(string email, string password, string role, CancellationToken cancellationToken = default);

    /// <summary>Deletes an account — used to undo a registration whose follow-up step failed.</summary>
    Task DeleteUserAsync(Guid userId, CancellationToken cancellationToken = default);
}

/// <summary>Outcome of an <see cref="IIdentityService"/> sign-in or refresh.</summary>
/// <param name="Succeeded">Whether the credentials or refresh token were valid.</param>
/// <param name="Token">The signed JWT access token, present only when <paramref name="Succeeded"/> is <c>true</c>.</param>
/// <param name="ExpiresAtUtc">UTC expiry of <paramref name="Token"/>, present only when <paramref name="Succeeded"/> is <c>true</c>.</param>
/// <param name="RefreshToken">Opaque token to trade for a new access token, present only when <paramref name="Succeeded"/> is <c>true</c>.</param>
/// <param name="UserId">The signed-in account.</param>
/// <param name="Roles">The account's roles.</param>
public sealed record AuthenticationResult(
    bool Succeeded,
    string? Token,
    DateTimeOffset? ExpiresAtUtc,
    string? RefreshToken = null,
    Guid? UserId = null,
    IReadOnlyList<string>? Roles = null);

/// <summary>Outcome of <see cref="IIdentityService.RegisterAsync"/>.</summary>
/// <param name="Succeeded">Whether the account was created.</param>
/// <param name="UserId">The new account, when <paramref name="Succeeded"/> is <c>true</c>.</param>
/// <param name="Errors">Why it failed (e.g. the email is taken or the password is too weak), keyed by field.</param>
public sealed record RegistrationResult(bool Succeeded, Guid? UserId, IReadOnlyDictionary<string, string[]> Errors);
