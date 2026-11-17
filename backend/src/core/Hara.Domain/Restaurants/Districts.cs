namespace Hara.Domain.Restaurants;

/// <summary>
/// The areas of Baku a restaurant can be placed in ("Ərazi" in the app). A fixed list, so the app can offer them as a filter and show the
/// names in every language; a restaurant has at most one.
/// </summary>
public static class Districts
{
    public static readonly IReadOnlyList<string> All =
    [
        "binagadi",
        "narimanov",
        "nasimi",
        "nizami",
        "pirallahi",
        "garadagh",
        "sabunchu",
        "sabail",
        "surakhani",
        "khatai",
        "khazar",
        "yasamal"
    ];

    public static bool IsKnown(string? code) => code is not null && All.Contains(code);
}
