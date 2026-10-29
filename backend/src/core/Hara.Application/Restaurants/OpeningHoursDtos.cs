using System.Globalization;
using Hara.Domain.Restaurants;

namespace Hara.Application.Restaurants;

/// <summary>One weekday's hours as the apps show and edit them. Times are "HH:mm" in Azerbaijan time.</summary>
/// <param name="Day">The weekday (0 = Sunday ... 6 = Saturday).</param>
/// <param name="IsClosed">Closed all day; no times then.</param>
/// <param name="Opens">Opening time, when open.</param>
/// <param name="Closes">Closing time, when open. At or before <paramref name="Opens"/> means after midnight; equal means all day.</param>
public sealed record DayHoursDto(DayOfWeek Day, bool IsClosed, string? Opens, string? Closes)
{
    public static DayHoursDto FromEntity(DayHours hours) => new(
        hours.Day,
        hours.IsClosed,
        hours.IsClosed ? null : OpeningTime.Format(hours.OpensAtMinute),
        hours.IsClosed ? null : OpeningTime.Format(hours.ClosesAtMinute));
}

/// <summary>Whether the restaurant can be asked for a table right now; the apps turn this into a sentence in the user's language.</summary>
/// <param name="AcceptingRequests">Whether a table request may be sent now.</param>
/// <param name="Reason">0 = open, 1 = closing so soon it takes no more requests, 2 = closed.</param>
/// <param name="ClosesAt">While open: the closing time today, "HH:mm".</param>
/// <param name="NextOpensInDays">While closed: 0 if it opens later today, 1 tomorrow, and so on.</param>
/// <param name="NextOpensDay">While closed: the weekday it opens next (0 = Sunday).</param>
/// <param name="NextOpensAt">While closed: the time it opens next, "HH:mm".</param>
public sealed record AvailabilityDto(
    bool AcceptingRequests,
    AvailabilityReason Reason,
    string? ClosesAt,
    int? NextOpensInDays,
    DayOfWeek? NextOpensDay,
    string? NextOpensAt)
{
    public static AvailabilityDto From(Availability availability) => new(
        availability.AcceptingRequests,
        availability.Reason,
        availability.ClosesAtMinute is { } closes ? OpeningTime.Format(closes) : null,
        availability.NextOpensInDays,
        availability.NextOpensDay,
        availability.NextOpensAtMinute is { } opens ? OpeningTime.Format(opens) : null);
}

/// <summary>"HH:mm" text and minutes-since-midnight, both ways.</summary>
public static class OpeningTime
{
    public static string Format(int minutes) => $"{minutes / 60:00}:{minutes % 60:00}";

    /// <summary>Minutes since midnight of an "HH:mm" text, or <c>null</c> if it is not a time of day.</summary>
    public static int? Parse(string? text) =>
        TimeOnly.TryParseExact(text, "HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out var time)
            ? time.Hour * 60 + time.Minute
            : null;
}
