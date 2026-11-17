using Hara.Domain.Common;

namespace Hara.Domain.Customers;

/// <summary>
/// What HARA knows about a customer who signed in with Google (to write reviews): the Google account's name, email and photo. The sign-in
/// itself is an Identity account (role Customer) with the same <see cref="BaseEntity.Id"/>; deleting that account deletes this and the reviews.
/// </summary>
public class CustomerProfile : BaseAuditableEntity
{
    /// <summary>The Firebase / Google account number: how the same person is recognised next time.</summary>
    public string FirebaseUid { get; set; } = string.Empty;

    public string? DisplayName { get; set; }

    public string? Email { get; set; }

    public string? PhotoUrl { get; set; }

    /// <summary>The name as other people see it next to a review: first name and the initial of the last ("Toghrul S."), never the email.</summary>
    public string? PublicName => ShortName(DisplayName);

    public static string? ShortName(string? name)
    {
        var parts = (name ?? string.Empty).Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        return parts.Length switch
        {
            0 => null,
            1 => parts[0],
            _ => $"{parts[0]} {char.ToUpperInvariant(parts[^1][0])}.",
        };
    }
}
