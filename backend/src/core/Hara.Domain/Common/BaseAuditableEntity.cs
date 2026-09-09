namespace Hara.Domain.Common;

public abstract class BaseAuditableEntity : BaseEntity
{
    public DateTimeOffset CreatedAt { get; set; }

    public DateTimeOffset? LastModifiedAt { get; set; }
}
