namespace Hara.Application.Common.Interfaces;

/// <summary>Sends email. The real one talks to an SMTP service (see the Infrastructure layer's Email settings).</summary>
public interface IEmailSender
{
    /// <summary>Sends the message, or throws <see cref="EmailDeliveryException"/> if it could not be sent.</summary>
    Task SendAsync(EmailMessage message, CancellationToken cancellationToken = default);
}

/// <summary>A plain-text email.</summary>
public sealed record EmailMessage(string To, string Subject, string Body);

/// <summary>Email could not be sent: not set up, the service refused it, or the address does not exist.</summary>
public class EmailDeliveryException(string message, Exception? inner = null) : Exception(message, inner);
