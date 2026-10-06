using Hara.Domain.Reservations;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class ReservationConfiguration : IEntityTypeConfiguration<Reservation>
{
    public void Configure(EntityTypeBuilder<Reservation> builder)
    {
        builder.Property(r => r.PhoneNumber).IsRequired().HasMaxLength(50);
        builder.Property(r => r.Code).IsRequired().HasMaxLength(16);
        builder.Property(r => r.Status).HasConversion<string>().HasMaxLength(20);

        builder.HasOne(r => r.Restaurant)
            .WithMany()
            .HasForeignKey(r => r.RestaurantId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(r => r.Code).IsUnique();
        builder.HasIndex(r => new { r.RestaurantId, r.Status });
    }
}
