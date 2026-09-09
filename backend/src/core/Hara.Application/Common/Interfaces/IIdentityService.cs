namespace Hara.Application.Common.Interfaces;

/// <summary>
/// Authenticates admin users and issues access tokens. Kept separate from
/// <see cref="IRepository{T}"/>/<see cref="IUnitOfWork"/> because identity
/// (password hashing, sign-in checks, token issuance) isn't a domain entity
/// CRUD concern — it's wrapped around ASP.NET Core Identity instead.
/// </summary>
public interface IIdentityService
{
    /// <summary>
    /// Validates an admin's credentials and, on success, issues a JWT bearer token.
    /// </summary>
    Task<AuthenticationResult> AuthenticateAsync(string email, string password, CancellationToken cancellationToken = default);
}

/// <summary>Outcome of an <see cref="IIdentityService.AuthenticateAsync"/> attempt.</summary>
/// <param name="Succeeded">Whether the credentials were valid.</param>
/// <param name="Token">The signed JWT bearer token, present only when <paramref name="Succeeded"/> is <c>true</c>.</param>
/// <param name="ExpiresAtUtc">UTC expiry of <paramref name="Token"/>, present only when <paramref name="Succeeded"/> is <c>true</c>.</param>
public sealed record AuthenticationResult(bool Succeeded, string? Token, DateTimeOffset? ExpiresAtUtc);
