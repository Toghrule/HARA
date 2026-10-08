namespace Hara.Application.Common;

/// <summary>
/// Picks which translation of a text to show. Azerbaijani is the base language
/// (stored in the original columns); Russian and English are optional extras.
/// </summary>
public static class Localization
{
    /// <summary>
    /// Returns the Russian or English text when <paramref name="language"/> asks for it and
    /// that translation is filled in; otherwise the Azerbaijani <paramref name="az"/> text.
    /// Unknown or missing languages are treated as Azerbaijani.
    /// </summary>
    public static string? Pick(string? language, string? az, string? ru, string? en)
    {
        var translated = language?.Trim().ToLowerInvariant() switch
        {
            "ru" => ru,
            "en" => en,
            _ => null,
        };

        return string.IsNullOrWhiteSpace(translated) ? az : translated;
    }
}
