import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/opening_hours.dart';
import '../availability_text.dart';

/// The seven days with their hours, Monday first.
class OpeningHoursList extends StatelessWidget {
  const OpeningHoursList({required this.hours, super.key});

  final List<DayHours> hours;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final byDay = {for (final day in hours) day.day: day};

    return Column(
      children: [
        for (final day in weekFromMonday)
          if (byDay[day] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.weekdayName('$day'))),
                  Text(
                    dayHoursText(l10n, byDay[day]!),
                    key: Key('hours-$day'),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
