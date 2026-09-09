namespace Hara.Domain.Common;

/// <summary>
/// Base class for every domain entity. Provides a client-generated, globally
/// unique identifier so entities can be created (and referenced, e.g. for
/// uploaded files) before they are ever persisted.
/// </summary>
public abstract class BaseEntity
{
    /// <summary>The entity's unique identifier.</summary>
    public Guid Id { get; set; } = Guid.NewGuid();
}
