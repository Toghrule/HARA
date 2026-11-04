using Hara.Domain.Members;
using Hara.Persistence.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Hara.Persistence.Configurations;

public class EmailVerificationConfiguration : IEntityTypeConfiguration<EmailVerification>
{
    public void Configure(EntityTypeBuilder<EmailVerification> builder)
    {
        builder.Property(v => v.Email).IsRequired().HasMaxLength(320);
        builder.Property(v => v.CodeHash).IsRequired().HasMaxLength(64);
        builder.Property(v => v.Salt).IsRequired().HasMaxLength(64);

        // The row goes with the account (when it is deleted, by the person or after a day unconfirmed).
        builder.HasOne<ApplicationUser>()
            .WithMany()
            .HasForeignKey(v => v.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // One waiting confirmation per account.
        builder.HasIndex(v => v.UserId).IsUnique();
        builder.HasIndex(v => v.CreatedAt);
    }
}
