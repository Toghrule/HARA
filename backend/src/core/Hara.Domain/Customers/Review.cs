using Hara.Domain.Common;
using Hara.Domain.Restaurants;

namespace Hara.Domain.Customers;

/// <summary>A signed-in customer's stars (1 to 5) and, if they wish, words about a restaurant. One per customer per restaurant; they can change or remove it.</summary>
public class Review : BaseAuditableEntity
{
    public const int MinStars = 1;
    public const int MaxStars = 5;
    public const int MaxTextLength = 1000;

    public Guid RestaurantId { get; set; }

    public Restaurant? Restaurant { get; set; }

    /// <summary>The customer (their <see cref="CustomerProfile"/>).</summary>
    public Guid CustomerId { get; set; }

    public CustomerProfile? Customer { get; set; }

    public int Stars { get; set; }

    public string? Text { get; set; }
}
