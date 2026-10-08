import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../reservations/data/reservation_state.dart';
import '../../data/venue_models.dart';
import '../../data/venue_repository.dart';
import '../providers/venue_providers.dart';

String _two(int value) => value.toString().padLeft(2, '0');

String formatClock(DateTime time) {
  final local = time.toLocal();

  return '${_two(local.hour)}:${_two(local.minute)}';
}

String formatDayAndClock(DateTime time) {
  final local = time.toLocal();

  return '${_two(local.day)}.${_two(local.month)} ${formatClock(time)}';
}

String reservationStatusText(AppLocalizations l10n, ReservationState status) => switch (status) {
      ReservationState.active => l10n.reservationStatusActive,
      ReservationState.redeemed => l10n.reservationStatusRedeemed,
      ReservationState.cancelled => l10n.reservationStatusCancelled,
      ReservationState.expired => l10n.reservationStatusExpired,
    };

/// A customer's reservation with everything a waiter needs to decide: the code, whether it is still good,
/// the discount to give and the customer's phone. A good code has the button that confirms it.
class ReservationDetailCard extends ConsumerStatefulWidget {
  const ReservationDetailCard({required this.reservation, this.onConfirmed, super.key});

  final VenueReservation reservation;

  /// Called with the confirmed reservation once the server accepted it.
  final ValueChanged<VenueReservation>? onConfirmed;

  @override
  ConsumerState<ReservationDetailCard> createState() => _ReservationDetailCardState();
}

class _ReservationDetailCardState extends ConsumerState<ReservationDetailCard> {
  late VenueReservation _reservation = widget.reservation;
  bool _confirming = false;
  bool _justConfirmed = false;
  String? _error;

  @override
  void didUpdateWidget(ReservationDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reservation.code != widget.reservation.code) {
      _reservation = widget.reservation;
      _justConfirmed = false;
      _error = null;
    }
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmCodeTitle),
        content: Text(l10n.confirmCodeBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            key: const Key('confirmDialogYes'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirmCode),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;

    setState(() {
      _confirming = true;
      _error = null;
    });

    try {
      final confirmed = await ref.read(venueRepositoryProvider).redeem(_reservation.code);
      if (!mounted) return;

      setState(() {
        _reservation = confirmed;
        _confirming = false;
        _justConfirmed = true;
      });
      ref.invalidate(venueReservationsProvider);
      widget.onConfirmed?.call(confirmed);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _confirming = false;
        _error = apiErrorMessage(error, l10n);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reservation = _reservation;
    final usable = reservation.isUsable && !_justConfirmed;
    final color = _justConfirmed
        ? Colors.green.shade700
        : usable
            ? theme.colorScheme.primary
            : theme.colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              reservation.code,
              key: const Key('detailCode'),
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
            const SizedBox(height: 8),
            Text(
              _justConfirmed ? l10n.codeConfirmed : reservationStatusText(l10n, reservation.effectiveStatus),
              key: const Key('detailStatus'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
            if (usable || _justConfirmed) ...[
              const SizedBox(height: 12),
              Text(
                _justConfirmed
                    ? l10n.codeConfirmedDetail
                    : reservation.discountPercent > 0
                        ? l10n.giveDiscount(reservation.discountPercent)
                        : l10n.noDiscountHere,
                key: const Key('detailDiscount'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 12),
            Text(l10n.customerPhoneLine(reservation.phoneNumber), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (usable)
              Text(l10n.validUntilLine(formatClock(reservation.expiresAt)), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            ],
            if (usable) ...[
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('confirmCode'),
                onPressed: _confirming ? null : _confirm,
                child: _confirming
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.confirmCode),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
