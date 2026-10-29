using Hara.Domain.Common;

namespace Hara.Domain.Members;

public enum PasswordResetStatus
{
    /// <summary>The owner asked; HARA has not decided yet.</summary>
    Pending = 0,

    /// <summary>HARA confirmed it is the owner. The owner may set a new password until <see cref="PasswordResetRequest.ExpiresAt"/>.</summary>
    Approved = 1,

    /// <summary>HARA declined.</summary>
    Rejected = 2,

    /// <summary>The owner set the new password. Used up.</summary>
    Completed = 3,

    /// <summary>Never stored: an approved request whose time ran out (see <see cref="PasswordResetRequest.EffectiveStatus"/>).</summary>
    Expired = 4
}

/// <summary>
/// An owner who forgot their password asks HARA to let them set a new one. HARA checks it really is the owner (for example
/// by phone) and approves; the owner's app then opens a form for the new password. Only the phone that made the request can
/// finish it: that phone was given a secret when it asked, and only a hash of it is kept here.
/// </summary>
public class PasswordResetRequest : BaseAuditableEntity
{
    /// <summary>How long an approved request can be used, in minutes.</summary>
    public const int ApprovedForMinutes = 60;

    /// <summary>The owner's account.</summary>
    public Guid UserId { get; set; }

    /// <summary>The sign-in email the request was made with.</summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>SHA-256 (hex) of the secret the requesting phone holds.</summary>
    public string SecretHash { get; set; } = string.Empty;

    /// <summary>Stored state. Never <see cref="PasswordResetStatus.Expired"/>; see <see cref="EffectiveStatus"/>.</summary>
    public PasswordResetStatus Status { get; set; } = PasswordResetStatus.Pending;

    /// <summary>When HARA approved or declined.</summary>
    public DateTimeOffset? DecidedAt { get; set; }

    /// <summary>When an approved request stops working.</summary>
    public DateTimeOffset? ExpiresAt { get; set; }

    /// <summary>When the owner set the new password.</summary>
    public DateTimeOffset? CompletedAt { get; set; }

    /// <summary>The state to show: an approved request past its time is <see cref="PasswordResetStatus.Expired"/>.</summary>
    public PasswordResetStatus EffectiveStatus(DateTimeOffset now) =>
        Status == PasswordResetStatus.Approved && ExpiresAt is { } expiresAt && expiresAt <= now ? PasswordResetStatus.Expired : Status;
}
