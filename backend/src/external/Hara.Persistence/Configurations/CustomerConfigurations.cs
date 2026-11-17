using Hara.Domain.Customers;
using Hara.Persistence.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class CustomerProfileConfiguration : IEntityTypeConfiguration<CustomerProfile>
{
    public void Configure(EntityTypeBuilder<CustomerProfile> builder)
    {
        builder.Property(c => c.FirebaseUid).IsRequired().HasMaxLength(128);
        builder.Property(c => c.DisplayName).HasMaxLength(200);
        builder.Property(c => c.Email).HasMaxLength(320);
        builder.Property(c => c.PhotoUrl).HasMaxLength(1000);
        builder.Ignore(c => c.PublicName);

        // The profile shares its number with the account it belongs to, and goes with it.
        builder.HasOne<ApplicationUser>()
            .WithOne()
            .HasForeignKey<CustomerProfile>(c => c.Id)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(c => c.FirebaseUid).IsUnique();
    }
}

public class ReviewConfiguration : IEntityTypeConfiguration<Review>
{
    public void Configure(EntityTypeBuilder<Review> builder)
    {
        builder.Property(r => r.Text).HasMaxLength(Review.MaxTextLength);

        builder.HasOne(r => r.Restaurant)
            .WithMany()
            .HasForeignKey(r => r.RestaurantId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(r => r.Customer)
            .WithMany()
            .HasForeignKey(r => r.CustomerId)
            .OnDelete(DeleteBehavior.Cascade);

        // One review per customer per restaurant, whatever happens at the same moment.
        builder.HasIndex(r => new { r.RestaurantId, r.CustomerId }).IsUnique();
        builder.HasIndex(r => new { r.RestaurantId, r.CreatedAt });

        builder.ToTable(table => table.HasCheckConstraint("CK_Reviews_Stars", "\"Stars\" BETWEEN 1 AND 5"));
    }
}
