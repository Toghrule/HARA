namespace Hara.Application.Common;

public static class SearchText
{
    /// <summary>
    /// Lower-cases text and maps the Azerbaijani/Turkish letters to their plain Latin look-alikes, so a
    /// search typed on a keyboard without them still matches: "mixek" finds "Mixək", "sirin" finds "Şirin"
    /// and "ISIQ" finds "ışıq". Applied to both the search term and the text searched.
    /// </summary>
    public static string Fold(string value)
    {
        var folded = new char[value.Length];
        var length = 0;

        foreach (var letter in value.Trim())
        {
            folded[length++] = letter switch
            {
                'ə' or 'Ə' => 'e',
                'ı' or 'İ' or 'I' => 'i',
                'ö' or 'Ö' => 'o',
                'ü' or 'Ü' => 'u',
                'ç' or 'Ç' => 'c',
                'ş' or 'Ş' => 's',
                'ğ' or 'Ğ' => 'g',
                _ => char.ToLowerInvariant(letter)
            };
        }

        return new string(folded, 0, length);
    }
}
