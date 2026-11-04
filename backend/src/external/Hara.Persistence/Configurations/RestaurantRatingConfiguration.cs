using Hara.Domain.Reservations;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class RestaurantRatingConfiguration : IEntityTypeConfiguration<RestaurantRating>
{
    public void Configure(EntityTypeBuilder<RestaurantRating> builder)
    {
        builder.Property(r => r.PhoneNumber).IsRequired().HasMaxLength(50);

        builder.HasOne(r => r.Restaurant)
            .WithMany()
            .HasForeignKey(r => r.RestaurantId)
            .OnDelete(DeleteBehavior.Cascade);

        // One rating per phone number per restaurant, whatever happens at the same moment.
        builder.HasIndex(r => new { r.RestaurantId, r.PhoneNumber }).IsUnique();

        builder.ToTable(table => table.HasCheckConstraint("CK_RestaurantRatings_Stars", "\"Stars\" BETWEEN 1 AND 5"));
    }
}
