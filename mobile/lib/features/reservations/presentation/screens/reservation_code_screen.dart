import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/reservation.dart';
import '../../data/reservation_state.dart';
import '../../data/reservations_repository.dart';
import '../providers/active_reservations_provider.dart';

/// The customer's reservation, from the moment they send the request to the end:
/// waiting for the restaurant (with the time it has to answer), accepted (the code to show at the venue and
/// the 30 minute countdown that started when the restaurant accepted), or declined / not answered.
/// It keeps itself up to date while it is open.
class ReservationCodeScreen extends ConsumerStatefulWidget {
  const ReservationCodeScreen({required this.reservation, super.key});

  /// What was known when the screen opened; the screen then follows the saved copy as it changes.
  final Reservation reservation;

  @override
  ConsumerState<ReservationCodeScreen> createState() => _ReservationCodeScreenState();
}

class _ReservationCodeScreenState extends ConsumerState<ReservationCodeScreen> {
  /// While waiting for the restaurant the answer can come at any moment; once accepted, a slower check will do.
  static const _pendingCheck = Duration(seconds: 10);
  static const _activeCheck = Duration(seconds: 30);

  Timer? _clock;
  late Reservation _last = widget.reservation;
  DateTime _lastCheck = DateTime.now();
  String? _deadlineHandled;
  bool _cancelling = false;

  // Set when the reservation disappeared (used, cancelled elsewhere) while the screen was open.
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});

    final reservation = _last;
    if (!reservation.status.isInProgress) return;

    // The deadline on this phone's clock passed: a request nobody answered becomes a notice; an accepted
    // reservation whose time ran out is over.
    final key = '${reservation.code}/${reservation.status.name}';
    if (!reservation.expiresAt.isAfter(DateTime.now()) && _deadlineHandled != key) {
      _deadlineHandled = key;
      unawaited(ref.read(activeReservationsProvider.notifier).deadlinePassed(reservation.code));
    }

    final every = reservation.status == ReservationState.pending ? _pendingCheck : _activeCheck;
    if (DateTime.now().difference(_lastCheck) >= every) {
      _lastCheck = DateTime.now();
      unawaited(ref.read(activeReservationsProvider.notifier).refresh());
    }
  }

  Duration _remaining(Reservation reservation) {
    final remaining = reservation.expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _countdown(Duration remaining) =>
      '${_two(remaining.inMinutes)}:${_two(remaining.inSeconds.remainder(60))}';

  static String _clockTime(DateTime time) {
    final local = time.toLocal();
    return '${_two(local.hour)}:${_two(local.minute)}';
  }

  Future<void> _cancel(Reservation reservation) async {
    final l10n = AppLocalizations.of(context);
    final waiting = reservation.status == ReservationState.pending;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(waiting ? l10n.cancelRequestTitle : l10n.cancelReservationTitle),
        content: Text(waiting ? l10n.cancelRequestBody : l10n.cancelReservationBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.keepIt),
          ),
          FilledButton(
            key: const Key('cancelDialogYes'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(waiting ? l10n.cancelRequest : l10n.cancelReservation),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(reservationsRepositoryProvider).cancel(reservation.code);
      // Forgetting the code on this device must never hold up the screen.
      unawaited(ref.read(activeReservationsProvider.notifier).remove(reservation.code));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(waiting ? l10n.requestCancelled : l10n.reservationCancelled)),
      );
      context.go('/');
    } catch (error) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      final notFound = error is DioException && error.response?.statusCode == 404;
      if (notFound) unawaited(ref.read(activeReservationsProvider.notifier).remove(reservation.code));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notFound ? l10n.reservationNotFound : apiErrorMessage(error, l10n))),
      );
    }
  }

  /// Leaves the screen; a notice about a declined or unanswered request is closed with it.
  Future<void> _done(Reservation reservation) async {
    if (!reservation.status.isInProgress) {
      unawaited(ref.read(activeReservationsProvider.notifier).remove(reservation.code));
    }
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = widget.reservation.code;

    // Follow the saved copy: the restaurant accepting the request changes the status and the deadline.
    final kept = ref.watch(activeReservationsProvider).where((reservation) => reservation.code == code).firstOrNull;
    if (kept != null) _last = kept;
    final reservation = _last;

    ref.listen<List<Reservation>>(activeReservationsProvider, (previous, next) {
      final wasKept = previous?.any((reservation) => reservation.code == code) ?? false;
      final isKept = next.any((reservation) => reservation.code == code);
      if (wasKept && !isKept && !_cancelling && !_ended && _remaining(_last) > Duration.zero) {
        setState(() => _ended = true);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.yourReservation), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: switch (reservation.status) {
                ReservationState.pending when !_ended => _buildWaiting(context, reservation),
                ReservationState.declined => _buildOutcome(
                    context,
                    reservation,
                    icon: Icons.highlight_off,
                    title: l10n.declinedTitle,
                    text: l10n.declinedText,
                  ),
                ReservationState.unanswered => _buildOutcome(
                    context,
                    reservation,
                    icon: Icons.hourglass_disabled,
                    title: l10n.unansweredTitle,
                    text: l10n.unansweredText,
                  ),
                _ => _buildCode(context, reservation),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaiting(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(reservation.restaurantName, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Icon(Icons.hourglass_top, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          l10n.waitingTitle,
          key: const Key('waitingTitle'),
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.waitingText(reservation.restaurantName, reservation.durationMinutes),
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.waitingCountdown(_countdown(_remaining(reservation))),
          key: const Key('waitingCountdown'),
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(
          key: const Key('done'),
          onPressed: _cancelling ? null : () => _done(reservation),
          child: Text(l10n.done),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('cancelRequest'),
          onPressed: _cancelling ? null : () => _cancel(reservation),
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          child: _cancelling
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.cancelRequest),
        ),
      ],
    );
  }

  Widget _buildOutcome(
    BuildContext context,
    Reservation reservation, {
    required IconData icon,
    required String title,
    required String text,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(reservation.restaurantName, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Icon(icon, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(title, key: const Key('outcomeTitle'), style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(text, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
        const SizedBox(height: 32),
        FilledButton(
          key: const Key('done'),
          onPressed: () => _done(reservation),
          child: Text(l10n.done),
        ),
      ],
    );
  }

  /// The accepted reservation: the code to show at the venue and the hold countdown.
  Widget _buildCode(BuildContext context, Reservation reservation) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final remaining = _remaining(reservation);
    final expiredByTime = remaining == Duration.zero;
    final expired = expiredByTime || _ended;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(reservation.restaurantName, style: textTheme.headlineSmall, textAlign: TextAlign.center),
        if (!expired) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: Colors.green.shade700),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.confirmedByRestaurant,
                  key: const Key('confirmedByRestaurant'),
                  style: textTheme.bodyMedium?.copyWith(color: Colors.green.shade700),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Text(l10n.yourCode, style: textTheme.labelLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Card(
          color: expired ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  reservation.code,
                  style: textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    decoration: expired ? TextDecoration.lineThrough : null,
                  ),
                ),
                IconButton(
                  tooltip: l10n.copyCode,
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: reservation.code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.codeCopied)));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _ended && !expiredByTime
              ? l10n.reservationEnded
              : expired
                  ? l10n.reservationExpired
                  : l10n.validFor(_countdown(remaining)),
          key: const Key('codeStatus'),
          style: textTheme.titleMedium?.copyWith(color: expired ? theme.colorScheme.error : null),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.tableHeldUntil(_clockTime(reservation.expiresAt), reservation.durationMinutes),
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          reservation.discountPercent > 0 ? l10n.showCodeWithDiscount(reservation.discountPercent) : l10n.showCode,
          style: textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(
          key: const Key('done'),
          onPressed: _cancelling ? null : () => _done(reservation),
          child: Text(l10n.done),
        ),
        if (!expired) ...[
          const SizedBox(height: 8),
          TextButton(
            key: const Key('cancelReservation'),
            onPressed: _cancelling ? null : () => _cancel(reservation),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: _cancelling
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.cancelReservation),
          ),
        ],
      ],
    );
  }
}
