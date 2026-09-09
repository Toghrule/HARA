using Hara.Domain.Restaurants;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class RestaurantSubmissionConfiguration : IEntityTypeConfiguration<RestaurantSubmission>
{
    public void Configure(EntityTypeBuilder<RestaurantSubmission> builder)
    {
        builder.Property(s => s.RestaurantName).IsRequired().HasMaxLength(200);
        builder.Property(s => s.Address).HasMaxLength(400);
        builder.Property(s => s.PhoneNumber).HasMaxLength(50);
        builder.Property(s => s.Description).HasMaxLength(4000);
        builder.Property(s => s.SubmitterName).IsRequired().HasMaxLength(200);
        builder.Property(s => s.SubmitterEmail).HasMaxLength(320);
        builder.Property(s => s.SubmitterPhoneNumber).HasMaxLength(50);
        builder.Property(s => s.AdminNote).HasMaxLength(1000);
        builder.Property(s => s.Status).HasConversion<string>().HasMaxLength(20);

        builder.HasIndex(s => s.Status);
    }
}
