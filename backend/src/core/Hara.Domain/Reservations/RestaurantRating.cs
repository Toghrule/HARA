using Hara.Domain.Common;
using Hara.Domain.Restaurants;

namespace Hara.Domain.Reservations;

/// <summary>
/// A customer's stars for a restaurant: one per phone number per restaurant, and only from someone whose reservation was
/// really used (the restaurant confirmed their code). Stars only, no text. The restaurant keeps a running total
/// (<see cref="Restaurant.RatingCount"/>, <see cref="Restaurant.RatingTotal"/>) so lists need no extra query.
/// </summary>
public class RestaurantRating : BaseAuditableEntity
{
    public const int MinStars = 1;
    public const int MaxStars = 5;

    public Guid RestaurantId { get; set; }

    public Restaurant? Restaurant { get; set; }

    /// <summary>The customer's phone number, normalized like the one on the reservation. The one rating per restaurant is kept by this.</summary>
    public string PhoneNumber { get; set; } = string.Empty;

    /// <summary>From <see cref="MinStars"/> to <see cref="MaxStars"/>.</summary>
    public int Stars { get; set; }
}
