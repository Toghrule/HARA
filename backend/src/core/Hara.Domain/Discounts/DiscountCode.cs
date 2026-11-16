using Hara.Domain.Common;
using Hara.Domain.Restaurants;

namespace Hara.Domain.Discounts;

/// <summary>
/// A discount code a customer got by tapping "get the discount" at a restaurant that gives one. No account and no phone number:
/// the phone is told apart only by an anonymous device number. The code is valid for <see cref="ValidHours"/> hours; the
/// restaurant's owner or a waiter confirms it, which gives the discount and counts the customer HARA brought.
/// A device gets one code per restaurant per day (Azerbaijan time), whether or not the first one was used.
/// </summary>
public class DiscountCode : BaseAuditableEntity
{
    /// <summary>How long a code can be confirmed after it was made.</summary>
    public const int ValidHours = 6;

    public Guid RestaurantId { get; set; }

    public Restaurant? Restaurant { get; set; }

    /// <summary>The short code the customer shows (letters and digits that are not easy to mix up).</summary>
    public string Code { get; set; } = string.Empty;

    /// <summary>The anonymous number the app made for the phone. Not a person, and a new one when the app is reinstalled.</summary>
    public string DeviceId { get; set; } = string.Empty;

    /// <summary>The restaurant's discount at the moment the code was made (0-100), so a later change does not alter codes already given.</summary>
    public int DiscountPercent { get; set; }

    /// <summary>The Azerbaijan-time day the code was made. With the restaurant and the device it is unique: the one code of the day.</summary>
    public DateOnly LocalDay { get; set; }

    public DateTimeOffset ExpiresAt { get; set; }

    /// <summary>When the restaurant confirmed the code, or <c>null</c> if it did not.</summary>
    public DateTimeOffset? RedeemedAt { get; set; }

    /// <summary>The owner or waiter who confirmed it.</summary>
    public Guid? RedeemedByUserId { get; set; }

    /// <summary>Can it still be confirmed at <paramref name="now"/>?</summary>
    public bool IsUsable(DateTimeOffset now) => RedeemedAt is null && ExpiresAt > now;
}
