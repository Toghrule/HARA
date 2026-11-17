namespace Hara.Application.Common.Interfaces;

/// <summary>Who a Google sign-in says the person is, once its token was checked.</summary>
/// <param name="Uid">The stable Firebase / Google account number.</param>
public sealed record GoogleIdentity(string Uid, string? Name, string? Email, string? PictureUrl);

/// <summary>Checks the token the app got when the customer signed in with Google.</summary>
public interface IGoogleTokenVerifier
{
    /// <summary>The person behind the token, or <c>null</c> when the token is not valid (wrong, expired, not from Google).</summary>
    Task<GoogleIdentity?> VerifyAsync(string idToken, CancellationToken cancellationToken = default);
}
