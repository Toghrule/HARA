namespace Hara.Domain.Common;

/// <summary>
/// Base class for entities that need to track when they were created and
/// last changed. Most admin-managed content (restaurants, ads, FAQ, etc.)
/// derives from this so the admin panel can show "last updated" info.
/// </summary>
public abstract class BaseAuditableEntity : BaseEntity
{
    /// <summary>UTC timestamp of when the entity was first persisted.</summary>
    public DateTimeOffset CreatedAt { get; set; }

    /// <summary>UTC timestamp of the most recent update, or <c>null</c> if it has never been modified.</summary>
    public DateTimeOffset? LastModifiedAt { get; set; }
}
