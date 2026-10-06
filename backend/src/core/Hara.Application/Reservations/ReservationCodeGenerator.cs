using System.Security.Cryptography;

namespace Hara.Application.Reservations;

internal static class ReservationCodeGenerator
{
    // No 0/O or 1/I so a code read aloud or copied by hand can't be misread.
    private const string Alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

    public const int Length = 6;

    public static string Generate() => new(RandomNumberGenerator.GetItems<char>(Alphabet, Length));
}
