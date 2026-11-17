using FirebaseAdmin.Auth;
using Hara.Application.Common.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Hara.Infrastructure.Notifications;

/// <summary>
/// Checks the Firebase token the app got when the customer signed in with Google. Only tokens of a Google sign-in count (not anonymous
/// or email ones). For automated tests only, <c>Auth:Google:AllowTestTokens</c> (never set on a real server) also accepts
/// <c>test:&lt;uid&gt;:&lt;name&gt;:&lt;email&gt;</c> instead of a real token.
/// </summary>
public sealed class GoogleTokenVerifier(IOptions<FirebaseOptions> options, IConfiguration configuration, ILogger<GoogleTokenVerifier> logger) : IGoogleTokenVerifier
{
    public async Task<GoogleIdentity?> VerifyAsync(string idToken, CancellationToken cancellationToken = default)
    {
        if (configuration.GetValue<bool>("Auth:Google:AllowTestTokens") && idToken.StartsWith("test:", StringComparison.Ordinal))
        {
            var parts = idToken.Split(':', 4);
            return parts.Length >= 2 && parts[1].Length > 0
                ? new GoogleIdentity(parts[1], parts.Length > 2 ? parts[2] : null, parts.Length > 3 ? parts[3] : null, null)
                : null;
        }

        var app = FirebaseAppFactory.GetOrCreate(options.Value.CredentialsPath);
        if (app is null)
        {
            logger.LogWarning("Google sign-in is off: no Firebase key file found (Firebase:CredentialsPath).");
            return null;
        }

        try
        {
            var decoded = await FirebaseAuth.GetAuth(app).VerifyIdTokenAsync(idToken, cancellationToken);

            // The sign-in has to be Google's.
            if (!decoded.Claims.TryGetValue("firebase", out var firebase) || !IsGoogle(firebase))
            {
                return null;
            }

            string? Claim(string key) => decoded.Claims.TryGetValue(key, out var value) ? value as string : null;

            return new GoogleIdentity(decoded.Uid, Claim("name"), Claim("email"), Claim("picture"));
        }
        catch (FirebaseAuthException)
        {
            return null;
        }
    }

    private static bool IsGoogle(object firebaseClaim) =>
        firebaseClaim is IDictionary<string, object> map && map.TryGetValue("sign_in_provider", out var provider) && provider is "google.com";
}
