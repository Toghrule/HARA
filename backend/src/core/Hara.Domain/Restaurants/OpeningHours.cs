namespace Hara.Domain.Restaurants;

/// <summary>
/// One weekday's opening hours. Times are minutes since midnight, in Azerbaijan time. A closing time at or before the
/// opening time means the restaurant stays open past midnight (18:00 to 02:00); equal times mean open the whole day.
/// </summary>
public class DayHours
{
    public DayOfWeek Day { get; set; }

    /// <summary>The restaurant is closed this whole day; the times below mean nothing then.</summary>
    public bool IsClosed { get; set; }

    public int OpensAtMinute { get; set; }

    public int ClosesAtMinute { get; set; }
}

/// <summary>Whether a restaurant can be asked for a table right now, and why not.</summary>
public enum AvailabilityReason
{
    /// <summary>Open, and far enough from closing time to take a request.</summary>
    Open = 0,

    /// <summary>Open, but closing so soon (see <see cref="Restaurant.LastRequestMinutesBeforeClose"/>) that it takes no more requests.</summary>
    ClosingSoon = 1,

    /// <summary>Closed.</summary>
    Closed = 2
}

/// <param name="AcceptingRequests">Whether a table request may be sent now.</param>
/// <param name="Reason">Why, in short.</param>
/// <param name="ClosesAtMinute">When it closes today (minutes since midnight), while it is open.</param>
/// <param name="NextOpensInDays">While closed: 0 if it opens later today, 1 tomorrow, and so on.</param>
/// <param name="NextOpensDay">While closed: the weekday it opens next.</param>
/// <param name="NextOpensAtMinute">While closed: the time it opens next (minutes since midnight).</param>
public sealed record Availability(
    bool AcceptingRequests,
    AvailabilityReason Reason,
    int? ClosesAtMinute = null,
    int? NextOpensInDays = null,
    DayOfWeek? NextOpensDay = null,
    int? NextOpensAtMinute = null);

public static class OpeningSchedule
{
    private const int MinutesPerDay = 24 * 60;
    private const int MinutesPerWeek = 7 * MinutesPerDay;

    /// <summary>
    /// What a restaurant with these hours offers at <paramref name="localNow"/> (Azerbaijan time). A restaurant that has
    /// not set any hours is taken as always open.
    /// </summary>
    public static Availability Evaluate(IReadOnlyCollection<DayHours> hours, int lastRequestMinutesBeforeClose, DateTime localNow)
    {
        if (hours.Count == 0)
        {
            return new Availability(true, AvailabilityReason.Open);
        }

        var now = (int)localNow.DayOfWeek * MinutesPerDay + localNow.Hour * 60 + localNow.Minute;

        // Each open stretch as minutes from the start of the (Sunday-first) week; copied a week before and after so
        // that a stretch running over the end of the week, or one still going from last week, is found too.
        var spans = new List<(int Start, int End, DayHours Hours)>();
        foreach (var day in hours.Where(h => !h.IsClosed))
        {
            var start = (int)day.Day * MinutesPerDay + day.OpensAtMinute;
            var length = ((day.ClosesAtMinute - day.OpensAtMinute) % MinutesPerDay + MinutesPerDay) % MinutesPerDay;
            if (length == 0)
            {
                length = MinutesPerDay;
            }

            foreach (var shift in new[] { -MinutesPerWeek, 0, MinutesPerWeek })
            {
                spans.Add((start + shift, start + shift + length, day));
            }
        }

        foreach (var span in spans.Where(s => s.Start <= now && now < s.End))
        {
            var closesIn = span.End - now;

            return new Availability(
                closesIn >= lastRequestMinutesBeforeClose,
                closesIn >= lastRequestMinutesBeforeClose ? AvailabilityReason.Open : AvailabilityReason.ClosingSoon,
                ClosesAtMinute: span.Hours.ClosesAtMinute);
        }

        var next = spans.Where(s => s.Start > now).OrderBy(s => s.Start).Cast<(int Start, int End, DayHours Hours)?>().FirstOrDefault();
        if (next is null)
        {
            return new Availability(false, AvailabilityReason.Closed);
        }

        var nextDay = next.Value.Start / MinutesPerDay;

        return new Availability(
            false,
            AvailabilityReason.Closed,
            NextOpensInDays: nextDay - now / MinutesPerDay,
            NextOpensDay: (DayOfWeek)(((nextDay % 7) + 7) % 7),
            NextOpensAtMinute: next.Value.Hours.OpensAtMinute);
    }
}
