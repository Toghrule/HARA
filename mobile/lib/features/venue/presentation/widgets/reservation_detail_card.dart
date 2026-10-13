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

String formatCountdown(Duration remaining) {
  final safe = remaining.isNegative ? Duration.zero : remaining;

  return '${_two(safe.inMinutes)}:${_two(safe.inSeconds.remainder(60))}';
}

String reservationStatusText(AppLocalizations l10n, ReservationState status) => switch (status) {
      ReservationState.active => l10n.reservationStatusActive,
      ReservationState.redeemed => l10n.reservationStatusRedeemed,
      ReservationState.cancelled => l10n.reservationStatusCancelled,
      ReservationState.expired => l10n.reservationStatusExpired,
      ReservationState.pending => l10n.reservationStatusPending,
      ReservationState.declined => l10n.reservationStatusDeclined,
      ReservationState.unanswered => l10n.reservationStatusUnanswered,
    };

/// A customer's request with everything a waiter needs to decide: the code, where it stands, the discount to give
/// and the customer's phone. A request still waiting has the buttons to accept or decline it (accepting starts the
/// customer's 30 minutes); an accepted one has the button that confirms the code when the customer arrives.
class ReservationDetailCard extends ConsumerStatefulWidget {
  const ReservationDetailCard({required this.reservation, this.onChanged, super.key});

  final VenueReservation reservation;

  /// Called with the updated reservation once the server accepted, declined or confirmed it.
  final ValueChanged<VenueReservation>? onChanged;

  @override
  ConsumerState<ReservationDetailCard> createState() => _ReservationDetailCardState();
}

enum _Outcome { accepted, declined, confirmed }

class _ReservationDetailCardState extends ConsumerState<ReservationDetailCard> {
  late VenueReservation _reservation = widget.reservation;
  bool _busy = false;
  _Outcome? _outcome;
  String? _error;

  @override
  void didUpdateWidget(ReservationDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reservation.code != widget.reservation.code) {
      _reservation = widget.reservation;
      _outcome = null;
      _error = null;
    }
  }

  /// Runs one server action and shows its result; a failure shows the reason and leaves the card as it was.
  Future<void> _run(Future<VenueReservation> Function(VenueRepository repository) action, _Outcome outcome) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final updated = await action(ref.read(venueRepositoryProvider));
      if (!mounted) return;

      setState(() {
        _reservation = updated;
        _busy = false;
        _outcome = outcome;
      });
      ref.invalidate(venueReservationsProvider);
      widget.onChanged?.call(updated);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _busy = false;
        _error = apiErrorMessage(error, l10n);
      });
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

    await _run((repository) => repository.redeem(_reservation.code), _Outcome.confirmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reservation = _reservation;
    final status = reservation.effectiveStatus;
    final waiting = reservation.isWaitingForAnswer;
    final usable = reservation.isUsable && _outcome != _Outcome.confirmed;
    final confirmed = _outcome == _Outcome.confirmed;

    final color = confirmed
        ? Colors.green.shade700
        : (waiting || usable)
            ? theme.colorScheme.primary
            : theme.colorScheme.error;

    final headline = confirmed
        ? l10n.codeConfirmed
        : _outcome == _Outcome.declined
            ? l10n.requestDeclinedDone
            : reservationStatusText(l10n, status);

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
              headline,
              key: const Key('detailStatus'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
            if (_outcome == _Outcome.accepted) ...[
              const SizedBox(height: 8),
              Text(
                l10n.requestAccepted(reservation.durationMinutes),
                key: const Key('acceptedNote'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (usable || confirmed) ...[
              const SizedBox(height: 12),
              Text(
                confirmed
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
            if (waiting)
              Text(
                l10n.answerWithin(formatCountdown(reservation.expiresAt.difference(DateTime.now()))),
                key: const Key('detailAnswerWithin'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            if (usable)
              Text(l10n.validUntilLine(formatClock(reservation.expiresAt)), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            ],
            if (waiting) ...[
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('acceptRequest'),
                onPressed: _busy ? null : () => _run((repository) => repository.accept(_reservation.code), _Outcome.accepted),
                child: _busy
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.acceptRequest),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('declineRequest'),
                onPressed: _busy ? null : () => _run((repository) => repository.decline(_reservation.code), _Outcome.declined),
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                child: Text(l10n.decline),
              ),
            ],
            if (usable) ...[
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('confirmCode'),
                onPressed: _busy ? null : _confirm,
                child: _busy
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
