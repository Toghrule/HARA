import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/language_menu.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../restaurants/data/opening_hours.dart';
import '../../../restaurants/presentation/availability_text.dart';
import '../../data/venue_me.dart';
import '../../data/venue_repository.dart';
import '../providers/venue_providers.dart';

/// The owner sets when the restaurant is open and how long before closing it stops taking requests. Saved at
/// once; no one has to approve it.
class OpeningHoursScreen extends ConsumerStatefulWidget {
  const OpeningHoursScreen({required this.restaurant, super.key});

  final VenueRestaurant restaurant;

  @override
  ConsumerState<OpeningHoursScreen> createState() => _OpeningHoursScreenState();
}

class _Row {
  _Row({required this.open, required this.opens, required this.closes});

  bool open;
  TimeOfDay opens;
  TimeOfDay closes;
}

class _OpeningHoursScreenState extends ConsumerState<OpeningHoursScreen> {
  /// What a day starts as when the restaurant has no hours yet.
  static const _defaultOpens = TimeOfDay(hour: 10, minute: 0);
  static const _defaultCloses = TimeOfDay(hour: 23, minute: 0);

  /// The "stop taking requests" lead times to choose from, in minutes.
  static const _leads = [0, 15, 30, 45, 60, 90, 120];

  late final Map<int, _Row> _rows;
  late int _lead;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final saved = {for (final day in widget.restaurant.openingHours) day.day: day};
    _rows = {
      for (final day in weekFromMonday)
        day: saved[day] == null
            ? _Row(open: true, opens: _defaultOpens, closes: _defaultCloses)
            : _Row(
                open: !saved[day]!.isClosed,
                opens: _parse(saved[day]!.opens) ?? _defaultOpens,
                closes: _parse(saved[day]!.closes) ?? _defaultCloses,
              ),
    };
    _lead = widget.restaurant.lastRequestMinutesBeforeClose;
  }

  static TimeOfDay? _parse(String? text) {
    final parts = text?.split(':');
    if (parts == null || parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    return hour == null || minute == null ? null : TimeOfDay(hour: hour, minute: minute);
  }

  static String _format(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(int day, {required bool opening}) async {
    final row = _rows[day]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: opening ? row.opens : row.closes,
      // Times are written like 18:00 everywhere in the app, so the picker is 24-hour too.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;

    setState(() => opening ? row.opens = picked : row.closes = picked);
  }

  void _sameEveryDay() {
    final first = _rows[weekFromMonday.first]!;
    setState(() {
      for (final row in _rows.values) {
        row
          ..open = true
          ..opens = first.opens
          ..closes = first.closes;
      }
    });
  }

  Future<void> _save({required bool remove}) async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(venueRepositoryProvider).updateOpeningHours(
            days: remove
                ? const []
                : [
                    for (final day in weekFromMonday)
                      _rows[day]!.open
                          ? DayHours(day: day, isClosed: false, opens: _format(_rows[day]!.opens), closes: _format(_rows[day]!.closes))
                          : DayHours(day: day, isClosed: true),
                  ],
            lastRequestMinutesBeforeClose: _lead,
          );
      ref.invalidate(venueMeProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).hoursSaved)));
      context.pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = apiErrorMessage(error, AppLocalizations.of(context));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final leads = {..._leads, _lead}.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.openingHoursTitle), actions: const [LanguageMenu()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.hoursHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final day in weekFromMonday)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(l10n.weekdayName('$day'), style: theme.textTheme.titleSmall)),
                        Text(_rows[day]!.open ? l10n.hoursOpenSwitch : l10n.hoursClosedDay),
                        Switch(
                          key: Key('open-$day'),
                          value: _rows[day]!.open,
                          onChanged: _saving ? null : (value) => setState(() => _rows[day]!.open = value),
                        ),
                      ],
                    ),
                    if (_rows[day]!.open)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: Key('opens-$day'),
                              onPressed: _saving ? null : () => _pick(day, opening: true),
                              child: Text('${l10n.hoursOpens} ${_format(_rows[day]!.opens)}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              key: Key('closes-$day'),
                              onPressed: _saving ? null : () => _pick(day, opening: false),
                              child: Text('${l10n.hoursCloses} ${_format(_rows[day]!.closes)}'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('sameEveryDay'),
              onPressed: _saving ? null : _sameEveryDay,
              icon: const Icon(Icons.content_copy_outlined),
              label: Text(l10n.hoursSameEveryDay),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            key: const Key('leadDropdown'),
            initialValue: _lead,
            decoration: InputDecoration(labelText: l10n.hoursLastRequest, border: const OutlineInputBorder()),
            items: [
              for (final minutes in leads)
                DropdownMenuItem(value: minutes, child: Text(minutes == 0 ? l10n.hoursLeadAtClose : l10n.hoursLeadMinutes(minutes))),
            ],
            onChanged: _saving ? null : (value) => setState(() => _lead = value ?? _lead),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, key: const Key('hoursError'), style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('saveHours'),
            onPressed: _saving ? null : () => _save(remove: false),
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.hoursSave),
          ),
          if (widget.restaurant.openingHours.isNotEmpty)
            TextButton(
              key: const Key('removeHours'),
              onPressed: _saving ? null : () => _save(remove: true),
              child: Text(l10n.hoursRemove),
            ),
        ],
      ),
    );
  }
}
