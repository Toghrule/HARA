using Hara.Domain.Common;

namespace Hara.Domain.Members;

/// <summary>
/// A new owner's or waiter's email address that has not been proven yet. The person gets a six-digit code by email and types
/// it into the app. While this row exists the account can do nothing for a restaurant; confirming the email removes it, so an
/// account without a row is a confirmed one (every account made before this check existed counts as confirmed). A row still here
/// after <see cref="KeepUnconfirmedHours"/> hours is deleted together with its account, so made-up addresses do not pile up.
/// </summary>
public class EmailVerification : BaseAuditableEntity
{
    /// <summary>How long a code works, in minutes.</summary>
    public const int CodeMinutes = 15;

    /// <summary>Wrong guesses allowed per code; after that a new code has to be asked for.</summary>
    public const int MaxFailedAttempts = 5;

    /// <summary>The wait between two codes, in seconds.</summary>
    public const int ResendCooldownSeconds = 60;

    /// <summary>Codes one account can ask for per hour (the first one included).</summary>
    public const int MaxSendsPerHour = 5;

    /// <summary>How long an account may stay unconfirmed before it is deleted, in hours.</summary>
    public const int KeepUnconfirmedHours = 24;

    public Guid UserId { get; set; }

    /// <summary>The address the code was sent to.</summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>SHA-256 (hex) of the salt followed by the code; the code itself is never stored.</summary>
    public string CodeHash { get; set; } = string.Empty;

    public string Salt { get; set; } = string.Empty;

    public DateTimeOffset CodeExpiresAt { get; set; }

    public int FailedAttempts { get; set; }

    public DateTimeOffset LastSentAt { get; set; }

    /// <summary>Codes sent since <see cref="SendWindowStartedAt"/>.</summary>
    public int SendsInWindow { get; set; }

    public DateTimeOffset SendWindowStartedAt { get; set; }
}
