namespace Hara.Application.Common;

public static class PhoneNumber
{
    public const int MinDigits = 7;

    /// <summary>E.164's upper bound for a phone number's digits.</summary>
    public const int MaxDigits = 15;

    /// <summary>
    /// Keeps the digits and a leading <c>+</c>, dropping spaces, dashes and brackets, so that
    /// "+994 50 123-45-67" and "+994501234567" are recognised as the same number.
    /// </summary>
    public static string Normalize(string value)
    {
        var trimmed = value.Trim();
        var digits = new string(trimmed.Where(char.IsAsciiDigit).ToArray());

        return trimmed.StartsWith('+') ? "+" + digits : digits;
    }

    public static bool HasValidDigitCount(string value)
    {
        var digits = value.Count(char.IsAsciiDigit);

        return digits is >= MinDigits and <= MaxDigits;
    }
}
