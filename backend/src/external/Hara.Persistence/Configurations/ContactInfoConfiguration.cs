using Hara.Domain.CompanyInfo;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class ContactInfoConfiguration : IEntityTypeConfiguration<ContactInfo>
{
    public void Configure(EntityTypeBuilder<ContactInfo> builder)
    {
        builder.Property(c => c.Value).IsRequired().HasMaxLength(320);
        builder.Property(c => c.Label).HasMaxLength(100);
        builder.Property(c => c.Type).HasConversion<string>().HasMaxLength(20);

        builder.HasIndex(c => new { c.IsActive, c.SortOrder });
    }
}
