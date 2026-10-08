using Hara.Domain.Restaurants;
using Hara.Persistence.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class RestaurantChangeRequestConfiguration : IEntityTypeConfiguration<RestaurantChangeRequest>
{
    public void Configure(EntityTypeBuilder<RestaurantChangeRequest> builder)
    {
        builder.Property(c => c.Name).HasMaxLength(200);
        builder.Property(c => c.Address).HasMaxLength(400);
        builder.Property(c => c.PhoneNumber).HasMaxLength(50);
        builder.Property(c => c.Description).HasMaxLength(4000);
        builder.Property(c => c.DescriptionRu).HasMaxLength(4000);
        builder.Property(c => c.DescriptionEn).HasMaxLength(4000);
        builder.Property(c => c.OwnerNote).HasMaxLength(1000);
        builder.Property(c => c.AdminNote).HasMaxLength(1000);
        builder.Property(c => c.Status).HasConversion<string>().HasMaxLength(20);

        builder.HasOne(c => c.Restaurant)
            .WithMany()
            .HasForeignKey(c => c.RestaurantId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne<ApplicationUser>()
            .WithMany()
            .HasForeignKey(c => c.RequestedByUserId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(c => new { c.RestaurantId, c.Status });
        builder.HasIndex(c => c.Status);
    }
}
