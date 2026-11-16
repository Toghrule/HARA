namespace Hara.Application.Statistics;

/// <summary>
/// "Today", "this month" and "this year" for the statistics are counted in Azerbaijan time (UTC+4, no daylight saving),
/// not in the server's. The results are UTC instants, which is what the database compares against.
/// </summary>
public static class BakuTime
{
    private static readonly TimeSpan Offset = TimeSpan.FromHours(4);

    public static DateTimeOffset StartOfDay(DateTimeOffset now)
    {
        var local = now.ToOffset(Offset);
        return new DateTimeOffset(local.Year, local.Month, local.Day, 0, 0, 0, Offset).ToUniversalTime();
    }

    public static DateTimeOffset StartOfMonth(DateTimeOffset now, int monthsBack = 0)
    {
        var local = now.ToOffset(Offset);
        return new DateTimeOffset(local.Year, local.Month, 1, 0, 0, 0, Offset).AddMonths(-monthsBack).ToUniversalTime();
    }

    /// <summary>The Azerbaijan-time calendar day of an instant.</summary>
    public static DateOnly DayOf(DateTimeOffset now) => DateOnly.FromDateTime(now.ToOffset(Offset).DateTime);

    /// <summary>Monday 00:00 (Azerbaijan time) of the week the instant is in.</summary>
    public static DateTimeOffset StartOfWeek(DateTimeOffset now)
    {
        var local = now.ToOffset(Offset);
        var daysSinceMonday = ((int)local.DayOfWeek + 6) % 7;
        return new DateTimeOffset(local.Year, local.Month, local.Day, 0, 0, 0, Offset).AddDays(-daysSinceMonday).ToUniversalTime();
    }

    /// <summary>Midnight (Azerbaijan time) at the start of a given month.</summary>
    public static DateTimeOffset StartOfMonth(int year, int month) => new DateTimeOffset(year, month, 1, 0, 0, 0, Offset).ToUniversalTime();

    public static DateTimeOffset StartOfYear(DateTimeOffset now)
    {
        var local = now.ToOffset(Offset);
        return new DateTimeOffset(local.Year, 1, 1, 0, 0, 0, Offset).ToUniversalTime();
    }
}
