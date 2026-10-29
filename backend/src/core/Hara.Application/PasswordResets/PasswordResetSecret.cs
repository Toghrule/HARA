using System.Security.Cryptography;
using System.Text;

namespace Hara.Application.PasswordResets;

/// <summary>
/// The secret the phone gets when it asks for a password reset and must show again to finish it. Only its hash is stored,
/// so a copy of the database does not let anyone finish somebody else's reset.
/// </summary>
public static class PasswordResetSecret
{
    /// <summary>A new random secret and the hash to store for it.</summary>
    public static (string Secret, string Hash) Create()
    {
        var secret = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32)).Replace('+', '-').Replace('/', '_').TrimEnd('=');

        return (secret, Hash(secret));
    }

    public static string Hash(string secret) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(secret)));

    /// <summary>Whether <paramref name="secret"/> is the one the stored hash was made from (compared in constant time).</summary>
    public static bool Matches(string secret, string storedHash) =>
        CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(Hash(secret)), Encoding.UTF8.GetBytes(storedHash));
}
