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

    public static DateTimeOffset StartOfYear(DateTimeOffset now)
    {
        var local = now.ToOffset(Offset);
        return new DateTimeOffset(local.Year, 1, 1, 0, 0, 0, Offset).ToUniversalTime();
    }
}
