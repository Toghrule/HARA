using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Hara.Application.Notifications;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Hara.Infrastructure.Notifications;

/// <summary>Where Firebase's service-account key is, from the <c>Firebase</c> appsettings section.</summary>
public class FirebaseOptions
{
    public const string SectionName = "Firebase";

    /// <summary>
    /// The service-account key file. Absolute, or relative: looked for in the app's folder and each folder above it,
    /// so <c>secrets/firebase-adminsdk.json</c> finds <c>backend/secrets/firebase-adminsdk.json</c>. Empty or missing
    /// means notifications are switched off (the rest of the app works the same).
    /// </summary>
    public string CredentialsPath { get; set; } = string.Empty;
}

/// <summary>Sends notifications through Firebase Cloud Messaging.</summary>
public sealed class FirebasePushSender : IPushSender
{
    private readonly FirebaseMessaging? _messaging;
    private readonly ILogger<FirebasePushSender> _logger;

    public FirebasePushSender(IOptions<FirebaseOptions> options, ILogger<FirebasePushSender> logger)
    {
        _logger = logger;

        var path = Resolve(options.Value.CredentialsPath);
        if (path is null)
        {
            _logger.LogWarning("Push notifications are off: no Firebase key file found (Firebase:CredentialsPath).");
            return;
        }

        try
        {
            var app = FirebaseApp.DefaultInstance ?? FirebaseApp.Create(new AppOptions { Credential = GoogleCredential.FromFile(path) });
            _messaging = FirebaseMessaging.GetMessaging(app);
        }
        catch (Exception exception)
        {
            _logger.LogError(exception, "Push notifications are off: the Firebase key file could not be used.");
        }
    }

    public async Task<IReadOnlyCollection<string>> SendAsync(IReadOnlyCollection<PushMessage> messages, CancellationToken cancellationToken)
    {
        if (_messaging is null || messages.Count == 0)
        {
            return [];
        }

        var invalid = new List<string>();

        // One message per phone (the text is in that phone's language), sent one by one: a restaurant has a handful of phones.
        foreach (var message in messages)
        {
            try
            {
                await _messaging.SendAsync(
                    new Message
                    {
                        Token = message.Token,
                        Notification = new Notification { Title = message.Title, Body = message.Body },
                        Data = message.Data.ToDictionary(pair => pair.Key, pair => pair.Value),
                        Android = new AndroidConfig
                        {
                            Priority = Priority.High,
                            Notification = new AndroidNotification { ChannelId = "hara_default", Sound = "default" }
                        }
                    },
                    cancellationToken);
            }
            catch (FirebaseMessagingException exception) when (exception.MessagingErrorCode is MessagingErrorCode.Unregistered or MessagingErrorCode.InvalidArgument)
            {
                // The app was uninstalled or the token is garbage: forget it.
                invalid.Add(message.Token);
            }
            catch (Exception exception) when (exception is not OperationCanceledException)
            {
                _logger.LogWarning(exception, "Firebase refused a notification.");
            }
        }

        return invalid;
    }

    private static string? Resolve(string configured)
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
}
