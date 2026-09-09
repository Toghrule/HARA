namespace Hara.Persistence.Identity;

/// <summary>JWT signing settings, bound from the <c>Jwt</c> appsettings section. Read by both <see cref="IdentityService"/> (to issue tokens) and the Api layer (to validate them) so they must agree.</summary>
public class JwtOptions
{
    public const string SectionName = "Jwt";

    /// <summary>Symmetric key used to sign tokens. Must be kept secret and be at least 32 characters for HS256.</summary>
    public string SigningKey { get; set; } = string.Empty;

    /// <summary>Token issuer (<c>iss</c> claim).</summary>
    public string Issuer { get; set; } = string.Empty;

    /// <summary>Token audience (<c>aud</c> claim).</summary>
    public string Audience { get; set; } = string.Empty;

    /// <summary>How long an issued access token remains valid.</summary>
    public int ExpiryMinutes { get; set; } = 60;
}
