using Hara.Domain.Common;

namespace Hara.Application.Common.Interfaces;

/// <summary>
/// Coordinates one or more <see cref="IRepository{T}"/> instances against a
/// single underlying persistence transaction, so a command handler that
/// touches multiple entities commits them atomically with one
/// <see cref="SaveChangesAsync"/> call.
/// </summary>
public interface IUnitOfWork
{
    /// <summary>Gets the repository for entity type <typeparamref name="T"/>.</summary>
    IRepository<T> Repository<T>() where T : BaseEntity;

    /// <summary>Persists all pending changes made through repositories obtained from this unit of work.</summary>
    /// <returns>The number of state entries written to the underlying store.</returns>
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
