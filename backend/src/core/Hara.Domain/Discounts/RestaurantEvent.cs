using Hara.Domain.Common;
using Hara.Domain.Restaurants;

namespace Hara.Domain.Discounts;

/// <summary>
/// Something a customer did with a restaurant in the app that HARA wants to count for the restaurant: opened its page, or opened the
/// way to it in maps. Anonymous: only the device number the app made.
/// </summary>
public class RestaurantEvent : BaseEntity
{
    public const string View = "view";
    public const string Directions = "directions";

    public static readonly string[] Types = [View, Directions];

    public Guid RestaurantId { get; set; }

    public Restaurant? Restaurant { get; set; }

    /// <summary>One of <see cref="Types"/>.</summary>
    public string Type { get; set; } = string.Empty;

    public string DeviceId { get; set; } = string.Empty;

    public DateTimeOffset CreatedAt { get; set; }
}
