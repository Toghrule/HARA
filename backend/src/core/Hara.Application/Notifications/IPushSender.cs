namespace Hara.Application.Notifications;

/// <summary>One notification to show on a phone. <see cref="Data"/> is read by the app when the person taps it.</summary>
public sealed record PushMessage(string Token, string Title, string Body, IReadOnlyDictionary<string, string> Data);

/// <summary>Delivers notifications to phones. Failing to deliver must never break the request that caused it.</summary>
public interface IPushSender
{
    /// <summary>Sends the messages and returns the tokens Firebase says are no longer valid, so they can be forgotten.</summary>
    Task<IReadOnlyCollection<string>> SendAsync(IReadOnlyCollection<PushMessage> messages, CancellationToken cancellationToken);
}
