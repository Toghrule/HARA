using Hara.Application.Common.Interfaces;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MimeKit;

namespace Hara.Infrastructure.Email;

/// <summary>
/// The <c>Email</c> settings. With a <see cref="Host"/> the app sends through that SMTP service (Brevo, Resend, any other); without
/// one nothing can be sent, unless <see cref="LogInstead"/> is on (development only): then the messages are written to the log.
/// The user name and password are secrets and live in <c>backend/secrets/local-settings.json</c>, never in git.
/// </summary>
public class EmailOptions
{
    public const string SectionName = "Email";

    public string Host { get; set; } = string.Empty;

    /// <summary>587 (STARTTLS) for most services; 465 means TLS from the first byte.</summary>
    public int Port { get; set; } = 587;

    public string UserName { get; set; } = string.Empty;

    public string Password { get; set; } = string.Empty;

    /// <summary>The sender address, on the domain whose DNS the service was told about (SPF/DKIM), e.g. noreply@hara.rest.</summary>
    public string FromAddress { get; set; } = "noreply@hara.rest";

    public string FromName { get; set; } = "HARA";

    /// <summary>Development: write the messages to the log instead of sending them.</summary>
    public bool LogInstead { get; set; }
}

/// <summary>Sends email through an SMTP service.</summary>
public sealed class SmtpEmailSender(IOptions<EmailOptions> options, ILogger<SmtpEmailSender> logger) : IEmailSender
{
    private readonly EmailOptions _options = options.Value;

    public async Task SendAsync(EmailMessage message, CancellationToken cancellationToken = default)
    {
        var mime = new MimeMessage();
        mime.From.Add(new MailboxAddress(_options.FromName, _options.FromAddress));
        mime.Subject = message.Subject;
        mime.Body = new TextPart("plain") { Text = message.Body };

        try
        {
            mime.To.Add(MailboxAddress.Parse(message.To));

            using var client = new SmtpClient();
            client.Timeout = 15_000;
            await client.ConnectAsync(_options.Host, _options.Port, _options.Port == 465 ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.Auto, cancellationToken);
            if (!string.IsNullOrEmpty(_options.UserName))
            {
                await client.AuthenticateAsync(_options.UserName, _options.Password, cancellationToken);
            }

            await client.SendAsync(mime, cancellationToken);
            await client.DisconnectAsync(true, cancellationToken);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            // The service's answer (a bad key, a refused address) is for the log, not for the person who is signing up.
            logger.LogError(exception, "The email to {To} could not be sent.", message.To);
            throw new EmailDeliveryException("The email could not be sent.", exception);
        }
    }
}

/// <summary>Development: the message goes to the log, where the confirmation code can be read, instead of to anyone.</summary>
public sealed class LoggingEmailSender(ILogger<LoggingEmailSender> logger) : IEmailSender
{
    public Task SendAsync(EmailMessage message, CancellationToken cancellationToken = default)
    {
        logger.LogWarning("EMAIL (not sent, development) EMAIL-TO:{To} SUBJECT:{Subject} BODY:{Body}", message.To, message.Subject, message.Body.Replace("\n", " | "));

        return Task.CompletedTask;
    }
}

/// <summary>No email service is set up: nothing can be sent, so sign-ups that need a confirmation email are refused.</summary>
public sealed class UnconfiguredEmailSender(ILogger<UnconfiguredEmailSender> logger) : IEmailSender
{
    public Task SendAsync(EmailMessage message, CancellationToken cancellationToken = default)
    {
        logger.LogError("No email service is set up (the Email:Host setting is empty), so the email to {To} was not sent.", message.To);

        throw new EmailDeliveryException("Email is not set up.");
    }
}
