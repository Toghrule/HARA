using Hara.Domain.Common;

namespace Hara.Domain.Restaurants;

/// <summary>
/// A restaurant published by the admin and shown to mobile app users.
/// Created either directly by an admin or by approving a <see cref="RestaurantSubmission"/>.
/// </summary>
public class Restaurant : BaseAuditableEntity
{
    /// <summary>Display name of the restaurant.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>Free-text description shown on the restaurant's detail screen.</summary>
    public string? Description { get; set; }

    /// <summary>Russian translation of <see cref="Description"/>; falls back to the Azerbaijani text when empty.</summary>
    public string? DescriptionRu { get; set; }

    /// <summary>English translation of <see cref="Description"/>; falls back to the Azerbaijani text when empty.</summary>
    public string? DescriptionEn { get; set; }

    /// <summary>Physical address of the restaurant.</summary>
    public string Address { get; set; } = string.Empty;

    /// <summary>Latitude of the restaurant's exact location, in decimal degrees.</summary>
    public double Latitude { get; set; }

    /// <summary>Longitude of the restaurant's exact location, in decimal degrees.</summary>
    public double Longitude { get; set; }

    /// <summary>Public-facing phone number, if the restaurant has one.</summary>
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// Relative URL of the restaurant's cover image, as returned by the
    /// upload endpoint. <c>null</c> when no image has been uploaded yet.
    /// </summary>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Percentage (0–100) the restaurant takes off the table bill when a customer
    /// presents a valid reservation code. <c>0</c> means the restaurant offers no discount.
    /// </summary>
    public int DiscountPercent { get; set; }

    /// <summary>
    /// Whether the restaurant is visible to mobile app users. Admins can
    /// deactivate a restaurant without deleting it (e.g. temporarily closed).
    /// </summary>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Opening hours, one entry per weekday. Empty means the owner has not set any, and the restaurant is taken as
    /// always open. Set by the owner in the app.
    /// </summary>
    public List<DayHours> OpeningHours { get; set; } = [];

    /// <summary>
    /// How long before closing time the restaurant stops taking table requests, in minutes (the owner chooses), so a
    /// customer is not sent to a restaurant that is about to close.
    /// </summary>
    public int LastRequestMinutesBeforeClose { get; set; } = 30;

    /// <summary>What this restaurant offers at <paramref name="utcNow"/>: open, closing soon or closed.</summary>
    public Availability AvailabilityAt(DateTimeOffset utcNow) =>
        OpeningSchedule.Evaluate(OpeningHours, LastRequestMinutesBeforeClose, utcNow.ToOffset(AzerbaijanOffset).DateTime);

    /// <summary>Azerbaijan time: UTC+4, no daylight saving.</summary>
    public static readonly TimeSpan AzerbaijanOffset = TimeSpan.FromHours(4);
}
