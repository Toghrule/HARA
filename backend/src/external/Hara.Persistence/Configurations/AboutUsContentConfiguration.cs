using Hara.Domain.CompanyInfo;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class AboutUsContentConfiguration : IEntityTypeConfiguration<AboutUsContent>
{
    public void Configure(EntityTypeBuilder<AboutUsContent> builder)
    {
        builder.Property(a => a.CompanyName).IsRequired().HasMaxLength(200);
        builder.Property(a => a.Description).IsRequired().HasMaxLength(8000);
        builder.Property(a => a.LogoUrl).HasMaxLength(1000);
    }
}
