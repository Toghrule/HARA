import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../restaurants/data/restaurant.dart';
import '../../data/reservation.dart';
import '../../data/reservations_repository.dart';

/// Bottom sheet that collects a phone number and hold time, then creates the
/// reservation. Pops with the created [Reservation], or `null` if dismissed.
class ReserveSheet extends ConsumerStatefulWidget {
  const ReserveSheet({required this.restaurant, super.key});

  final Restaurant restaurant;

  @override
  ConsumerState<ReserveSheet> createState() => _ReserveSheetState();
}

class _ReserveSheetState extends ConsumerState<ReserveSheet> {
  static final _phonePattern = RegExp(r'^\+?[0-9\s\-()]{7,20}$');

  final _phoneController = TextEditingController();
  int _durationMinutes = 30;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    if (!_phonePattern.hasMatch(phone)) {
      setState(() => _error = AppLocalizations.of(context).invalidPhone);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final reservation = await ref.read(reservationsRepositoryProvider).create(
            restaurantId: widget.restaurant.id,
            phoneNumber: phone,
            durationMinutes: _durationMinutes,
          );
      if (mounted) Navigator.of(context).pop(reservation);
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = apiErrorMessage(error, AppLocalizations.of(context));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final discount = widget.restaurant.discountPercent;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.reserveTable, style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(widget.restaurant.name, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              discount > 0
                  ? l10n.reserveSheetFreeWithDiscount(discount)
                  : l10n.reserveSheetFree,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              enabled: !_submitting,
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                hintText: '+994 50 123 45 67',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Text(l10n.holdTableFor, style: textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 30, label: Text(l10n.minutesShort(30))),
                ButtonSegment(value: 60, label: Text(l10n.minutesShort(60))),
              ],
              selected: {_durationMinutes},
              onSelectionChanged: _submitting
                  ? null
                  : (selection) => setState(() => _durationMinutes = selection.first),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.reserve),
            ),
          ],
        ),
      ),
    );
  }
}
