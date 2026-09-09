using Hara.Domain.CompanyInfo;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class SocialMediaLinkConfiguration : IEntityTypeConfiguration<SocialMediaLink>
{
    public void Configure(EntityTypeBuilder<SocialMediaLink> builder)
    {
        builder.Property(s => s.Url).IsRequired().HasMaxLength(1000);
        builder.Property(s => s.Platform).HasConversion<string>().HasMaxLength(20);

        builder.HasIndex(s => new { s.IsActive, s.SortOrder });
    }
}
