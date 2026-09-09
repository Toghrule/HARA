using Hara.Domain.Advertisements;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class AdvertisementConfiguration : IEntityTypeConfiguration<Advertisement>
{
    public void Configure(EntityTypeBuilder<Advertisement> builder)
    {
        builder.Property(a => a.Title).HasMaxLength(200);
        builder.Property(a => a.ImageUrl).IsRequired().HasMaxLength(1000);
        builder.Property(a => a.LinkUrl).HasMaxLength(1000);

        builder.HasIndex(a => new { a.IsActive, a.SortOrder });
    }
}
