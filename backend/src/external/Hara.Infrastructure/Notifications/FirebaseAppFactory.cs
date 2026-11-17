using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;

namespace Hara.Infrastructure.Notifications;

/// <summary>One place that finds the Firebase key file and starts the one Firebase app that both notifications and Google sign-in use.</summary>
public static class FirebaseAppFactory
{
    private static readonly object Gate = new();

    /// <summary>The key file: absolute, or relative and looked for in the app's folder and each folder above it. <c>null</c> when there is none.</summary>
    public static string? Resolve(string configured)
    {
        if (string.IsNullOrWhiteSpace(configured))
        {
            return null;
        }

        if (Path.IsPathRooted(configured))
        {
            return File.Exists(configured) ? configured : null;
        }

        foreach (var start in new[] { AppContext.BaseDirectory, Directory.GetCurrentDirectory() })
        {
            for (var directory = new DirectoryInfo(start); directory is not null; directory = directory.Parent)
            {
                var candidate = Path.Combine(directory.FullName, configured);
                if (File.Exists(candidate))
                {
                    return candidate;
                }
            }
        }

        return null;
    }

    /// <summary>The Firebase app, started on first use; <c>null</c> when there is no key file.</summary>
    public static FirebaseApp? GetOrCreate(string configuredPath)
    {
        lock (Gate)
        {
            if (FirebaseApp.DefaultInstance is { } existing)
            {
                return existing;
            }

            var path = Resolve(configuredPath);
            return path is null
                ? null
                : FirebaseApp.Create(new AppOptions { Credential = CredentialFactory.FromFile<ServiceAccountCredential>(path).ToGoogleCredential() });
        }
    }
}
