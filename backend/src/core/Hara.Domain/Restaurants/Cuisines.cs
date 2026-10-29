namespace Hara.Domain.Restaurants;

/// <summary>
/// The kinds of cuisine a restaurant can be filed under. A fixed list, so the app can offer filters and show the names in
/// every language; a restaurant picks up to <see cref="MaxPerRestaurant"/> of them.
/// </summary>
public static class Cuisines
{
    public const int MaxPerRestaurant = 3;

    public static readonly IReadOnlyList<string> All =
    [
        "azerbaijani",
        "kebab",
        "european",
        "italian",
        "turkish",
        "georgian",
        "asian",
        "seafood",
        "fastfood",
        "pizza",
        "cafe",
        "dessert"
    ];

    public static bool IsKnown(string? code) => code is not null && All.Contains(code);
}
