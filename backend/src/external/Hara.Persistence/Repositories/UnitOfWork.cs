using System.Collections.Concurrent;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Common;

namespace Hara.Persistence.Repositories;

/// <summary>
/// EF Core-backed <see cref="IUnitOfWork"/>. Lazily creates and caches one
/// <see cref="Repository{T}"/> per entity type so multiple calls to
/// <see cref="Repository{T}"/> within the same scope share state, and commits
/// everything through the single underlying <see cref="ApplicationDbContext"/>.
/// </summary>
public sealed class UnitOfWork(ApplicationDbContext dbContext) : IUnitOfWork
{
    private readonly ConcurrentDictionary<Type, object> _repositories = new();

    public IRepository<T> Repository<T>() where T : BaseEntity =>
        (IRepository<T>)_repositories.GetOrAdd(typeof(T), _ => new Repository<T>(dbContext));

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) =>
        dbContext.SaveChangesAsync(cancellationToken);
}
