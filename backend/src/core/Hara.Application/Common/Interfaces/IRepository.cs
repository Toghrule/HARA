using System.Linq.Expressions;
using Hara.Domain.Common;

namespace Hara.Application.Common.Interfaces;

/// <summary>
/// Generic data-access contract for a single <see cref="BaseEntity"/> type.
/// Handlers depend on this (via <see cref="IUnitOfWork"/>) instead of EF Core
/// directly, keeping the Application layer persistence-ignorant.
/// </summary>
/// <typeparam name="T">The entity type this repository manages.</typeparam>
public interface IRepository<T> where T : BaseEntity
{
    /// <summary>Fetches a single entity by id, or <c>null</c> if it doesn't exist.</summary>
    Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>Fetches the first entity matching <paramref name="predicate"/>, or <c>null</c> if none match.</summary>
    Task<T?> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default);

    /// <summary>
    /// Read-only composable query over the entity set. Exists so handlers can
    /// filter, order and page reads (e.g. "active items ordered by SortOrder")
    /// without the repository needing a bespoke method per query shape.
    /// </summary>
    IQueryable<T> Query();

    /// <summary>Registers a new entity to be inserted on the next <see cref="IUnitOfWork.SaveChangesAsync"/>.</summary>
    Task AddAsync(T entity, CancellationToken cancellationToken = default);

    /// <summary>Marks an already-tracked-or-attached entity as modified.</summary>
    void Update(T entity);

    /// <summary>Registers an entity to be deleted on the next <see cref="IUnitOfWork.SaveChangesAsync"/>.</summary>
    void Remove(T entity);
}
