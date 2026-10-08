using Hara.Domain.Members;
using Hara.Persistence.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class RestaurantMemberConfiguration : IEntityTypeConfiguration<RestaurantMember>
{
    public void Configure(EntityTypeBuilder<RestaurantMember> builder)
    {
        builder.Property(m => m.FullName).IsRequired().HasMaxLength(200);
        builder.Property(m => m.Email).IsRequired().HasMaxLength(320);
        builder.Property(m => m.PhoneNumber).HasMaxLength(50);
        builder.Property(m => m.Role).HasConversion<string>().HasMaxLength(20);
        builder.Property(m => m.Status).HasConversion<string>().HasMaxLength(20);

        builder.HasOne(m => m.Restaurant)
            .WithMany()
            .HasForeignKey(m => m.RestaurantId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne<ApplicationUser>()
            .WithMany()
            .HasForeignKey(m => m.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // One account works at one restaurant.
        builder.HasIndex(m => m.UserId).IsUnique();
        builder.HasIndex(m => new { m.RestaurantId, m.Status });
    }
}
