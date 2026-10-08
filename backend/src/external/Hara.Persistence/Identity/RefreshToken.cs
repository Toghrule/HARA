namespace Hara.Persistence.Identity;

/// <summary>
/// One signed-in device's long-lived session. Only a hash of the token is stored, so a copy of the
/// database doesn't let anyone sign in. A token is used once: refreshing revokes it and issues the next.
/// </summary>
public class RefreshToken
{
    public Guid Id { get; set; }

    /// <summary>The account this session belongs to.</summary>
    public Guid UserId { get; set; }

    /// <summary>SHA-256 (hex) of the token the app holds.</summary>
    public string TokenHash { get; set; } = string.Empty;

    public DateTimeOffset CreatedAt { get; set; }

    /// <summary>After this the token no longer works and the user must sign in again.</summary>
    public DateTimeOffset ExpiresAt { get; set; }

    /// <summary>Set when the token was used up by a refresh, or the user signed out.</summary>
    public DateTimeOffset? RevokedAt { get; set; }
}
