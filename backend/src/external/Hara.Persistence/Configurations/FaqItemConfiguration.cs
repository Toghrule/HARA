using Hara.Domain.Faq;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class FaqItemConfiguration : IEntityTypeConfiguration<FaqItem>
{
    public void Configure(EntityTypeBuilder<FaqItem> builder)
    {
        builder.Property(f => f.Question).IsRequired().HasMaxLength(500);
        builder.Property(f => f.Answer).IsRequired().HasMaxLength(4000);

        builder.HasIndex(f => new { f.IsActive, f.SortOrder });
    }
}
