using Hara.Domain.Restaurants;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class RestaurantConfiguration : IEntityTypeConfiguration<Restaurant>
{
    public void Configure(EntityTypeBuilder<Restaurant> builder)
    {
        builder.Property(r => r.Name).IsRequired().HasMaxLength(200);
        builder.Property(r => r.Address).IsRequired().HasMaxLength(400);
        builder.Property(r => r.PhoneNumber).HasMaxLength(50);
        builder.Property(r => r.ImageUrl).HasMaxLength(1000);
        builder.Property(r => r.Description).HasMaxLength(4000);

        builder.HasIndex(r => r.IsActive);
    }
}
