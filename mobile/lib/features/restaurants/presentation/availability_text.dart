import '../../../l10n/app_localizations.dart';
import '../data/opening_hours.dart';

/// One short sentence on whether the restaurant takes requests now: "Open until 23:00", "Closed, opens tomorrow at 10:00".
String availabilityText(AppLocalizations l10n, Availability availability) {
  switch (availability.reason) {
    case AvailabilityReason.open:
      final closesAt = availability.closesAt;

      return closesAt == null ? '' : l10n.availOpenUntil(closesAt);
    case AvailabilityReason.closingSoon:
      return l10n.availClosingSoon(availability.closesAt ?? '');
    case AvailabilityReason.closed:
      final opensAt = availability.nextOpensAt;
      if (opensAt == null) return l10n.availClosed;

      return switch (availability.nextOpensInDays) {
        0 => l10n.availClosedOpensToday(opensAt),
        1 => l10n.availClosedOpensTomorrow(opensAt),
        _ => l10n.availClosedOpensOn(l10n.weekdayOn('${availability.nextOpensDay ?? 0}'), opensAt),
      };
  }
}

/// What one weekday's hours say: "10:00 – 23:00", "Closed" or "Open 24 hours".
String dayHoursText(AppLocalizations l10n, DayHours hours) {
  if (hours.isClosed) return l10n.hoursClosedDay;
  if (hours.isAllDay) return l10n.hoursAllDay;

  return '${hours.opens} – ${hours.closes}';
}

/// The days in the order people read them: Monday first, Sunday last (the server counts Sunday as 0).
const weekFromMonday = [1, 2, 3, 4, 5, 6, 0];
