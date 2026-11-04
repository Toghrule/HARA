import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/hara_ui.dart';
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
            durationMinutes: reservationHoldMinutes,
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final discount = widget.restaurant.discountPercent;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.table_restaurant_outlined, color: scheme.onPrimaryContainer, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.reserveTable, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(widget.restaurant.name, style: textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (discount > 0) DiscountBadge(percent: discount),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              discount > 0 ? l10n.reserveSheetFreeWithDiscount(discount) : l10n.reserveSheetFree,
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
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
                prefixIcon: const Icon(Icons.phone_outlined),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.secondaryContainer.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, size: 20, color: scheme.onSecondaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.requestNotice(l10n.minutesShort(reservationHoldMinutes)),
                      key: const Key('holdNotice'),
                      style: textTheme.bodyMedium?.copyWith(color: scheme.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: textTheme.bodyMedium?.copyWith(color: scheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.sendRequest),
            ),
          ],
        ),
      ),
    );
  }
}
