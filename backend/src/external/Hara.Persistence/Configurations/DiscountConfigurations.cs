using Hara.Domain.Discounts;
using Hara.Persistence.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class DiscountCodeConfiguration : IEntityTypeConfiguration<DiscountCode>
{
    public void Configure(EntityTypeBuilder<DiscountCode> builder)
    {
        builder.Property(c => c.Code).IsRequired().HasMaxLength(16);
        builder.Property(c => c.DeviceId).IsRequired().HasMaxLength(64);

        builder.HasOne(c => c.Restaurant)
            .WithMany()
            .HasForeignKey(c => c.RestaurantId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne<ApplicationUser>()
            .WithMany()
            .HasForeignKey(c => c.RedeemedByUserId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(c => c.Code).IsUnique();

        // The one code of the day for a device at a restaurant, whatever happens at the same moment.
        builder.HasIndex(c => new { c.RestaurantId, c.DeviceId, c.LocalDay }).IsUnique();
    }
}

public class RestaurantEventConfiguration : IEntityTypeConfiguration<RestaurantEvent>
{
    public void Configure(EntityTypeBuilder<RestaurantEvent> builder)
    {
        builder.Property(e => e.Type).IsRequired().HasMaxLength(20);
        builder.Property(e => e.DeviceId).IsRequired().HasMaxLength(64);

        builder.HasOne(e => e.Restaurant)
            .WithMany()
            .HasForeignKey(e => e.RestaurantId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(e => new { e.RestaurantId, e.CreatedAt });
    }
}
