using System.Linq.Expressions;
using Hara.Application.Common.Interfaces;
using Hara.Domain.Common;
using Microsoft.EntityFrameworkCore;

namespace Hara.Persistence.Repositories;

/// <summary>EF Core-backed implementation of <see cref="IRepository{T}"/>, shared by every entity type via the <see cref="DbContext.Set{TEntity}"/> generic API.</summary>
internal sealed class Repository<T>(ApplicationDbContext dbContext) : IRepository<T> where T : BaseEntity
{
    private readonly DbSet<T> _set = dbContext.Set<T>();

    public async Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        await _set.FindAsync([id], cancellationToken);

    public Task<T?> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default) =>
        _set.FirstOrDefaultAsync(predicate, cancellationToken);

    public IQueryable<T> Query() => _set.AsQueryable();

    public async Task AddAsync(T entity, CancellationToken cancellationToken = default) =>
        await _set.AddAsync(entity, cancellationToken);

    public void Update(T entity) => _set.Update(entity);

    public void Remove(T entity) => _set.Remove(entity);
}
