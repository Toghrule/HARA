using System.Reflection;
using Hara.Domain.Advertisements;
using Hara.Domain.CompanyInfo;
using Hara.Domain.Common;
using Hara.Domain.Faq;
using Hara.Domain.Restaurants;
using Hara.Persistence.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace Hara.Persistence;

/// <summary>
/// EF Core database context for HARA. Combines the domain data (restaurants,
/// ads, company info, FAQ) with ASP.NET Core Identity's admin-user tables in
/// a single database. Consumed only through <see cref="Hara.Application.Common.Interfaces.IUnitOfWork"/>
/// and <see cref="Hara.Application.Common.Interfaces.IRepository{T}"/> — Application code never references this type directly.
/// </summary>
public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
    : IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>(options)
{
    public DbSet<Restaurant> Restaurants => Set<Restaurant>();

    public DbSet<RestaurantSubmission> RestaurantSubmissions => Set<RestaurantSubmission>();

    public DbSet<Advertisement> Advertisements => Set<Advertisement>();

    public DbSet<AboutUsContent> AboutUsContents => Set<AboutUsContent>();

    public DbSet<SocialMediaLink> SocialMediaLinks => Set<SocialMediaLink>();

    public DbSet<ContactInfo> ContactInfos => Set<ContactInfo>();

    public DbSet<FaqItem> FaqItems => Set<FaqItem>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }

    /// <summary>Stamps <see cref="BaseAuditableEntity.CreatedAt"/>/<see cref="BaseAuditableEntity.LastModifiedAt"/> before delegating to EF Core, so handlers never have to set them manually.</summary>
    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTimeOffset.UtcNow;

        foreach (var entry in ChangeTracker.Entries<BaseAuditableEntity>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedAt = now;
                    break;
                case EntityState.Modified:
                    entry.Entity.LastModifiedAt = now;
                    break;
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}
