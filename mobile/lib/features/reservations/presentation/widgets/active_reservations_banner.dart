import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/reservation.dart';
import '../../data/reservation_state.dart';
import '../providers/active_reservations_provider.dart';

/// A card per reservation still going at the top of the restaurant list, so the customer can open it again
/// at any time: a request waiting for the restaurant, or an accepted one with its code. A request the
/// restaurant declined (or never answered) stays as a notice until the customer closes it. Cards are kept up
/// to date: checked with the server when the list opens, when the app comes back to the foreground, every
/// [_checkInterval] while a request is waiting, and about once a minute otherwise.
class ActiveReservationsBanner extends ConsumerStatefulWidget {
  const ActiveReservationsBanner({super.key});

  @override
  ConsumerState<ActiveReservationsBanner> createState() => _ActiveReservationsBannerState();
}

class _ActiveReservationsBannerState extends ConsumerState<ActiveReservationsBanner>
    with WidgetsBindingObserver {
  static const _checkInterval = Duration(seconds: 10);
  static const _slowChecksEvery = 6; // 6 x 10 s = once a minute when nothing is waiting for an answer

  Timer? _checkTimer;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    _checkTimer = Timer.periodic(_checkInterval, (_) => _onTick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  void _onTick() {
    _ticks++;
    final waiting = ref.read(activeReservationsProvider).any((reservation) => reservation.status == ReservationState.pending);
    if (waiting || _ticks % _slowChecksEvery == 0) _check();
  }

  void _check() => unawaited(ref.read(activeReservationsProvider.notifier).refresh());

  @override
  Widget build(BuildContext context) {
    final reservations = ref.watch(activeReservationsProvider);
    if (reservations.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final reservation in reservations)
          _ReservationCard(key: ValueKey(reservation.code), reservation: reservation),
      ],
    );
  }
}

class _ReservationCard extends ConsumerStatefulWidget {
  const _ReservationCard({required this.reservation, super.key});

  final Reservation reservation;

  @override
  ConsumerState<_ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends ConsumerState<_ReservationCard> {
  Timer? _timer;
  String? _deadlineHandled;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final remaining = widget.reservation.expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _tick() {
    if (!mounted) return;

    final reservation = widget.reservation;
    if (reservation.status.isInProgress && _remaining == Duration.zero) {
      // The deadline passed on this phone's clock: an unanswered request becomes a notice, a finished hold goes away.
      final key = '${reservation.code}/${reservation.status.name}';
      if (_deadlineHandled != key) {
        _deadlineHandled = key;
        unawaited(ref.read(activeReservationsProvider.notifier).deadlinePassed(reservation.code));
      }
      return;
    }

    setState(() {});
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reservation = widget.reservation;
    final theme = Theme.of(context);
    final remaining = _remaining;
    final countdown = '${_two(remaining.inMinutes)}:${_two(remaining.inSeconds.remainder(60))}';

    final isNotice = !reservation.status.isInProgress;
    final background = isNotice ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer;
    final foreground = isNotice ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer;

    final (IconData icon, String title, String subtitle) = switch (reservation.status) {
      ReservationState.pending => (
          Icons.hourglass_top,
          '${l10n.yourReservation}: ${reservation.restaurantName}',
          l10n.bannerWaiting(countdown),
        ),
      ReservationState.declined => (Icons.highlight_off, l10n.bannerDeclined(reservation.restaurantName), l10n.declinedText),
      ReservationState.unanswered => (
          Icons.hourglass_disabled,
          l10n.bannerUnanswered(reservation.restaurantName),
          l10n.unansweredText,
        ),
      _ => (
          Icons.confirmation_number_outlined,
          '${l10n.yourReservation}: ${reservation.restaurantName}',
          l10n.activeReservationSubtitle(reservation.code, countdown),
        ),
    };

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: background,
      child: ListTile(
        key: Key('reservationCard-${reservation.code}'),
        leading: Icon(icon, color: foreground),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: foreground)),
        subtitle: Text(subtitle, style: TextStyle(color: foreground)),
        trailing: isNotice
            ? IconButton(
                key: Key('closeNotice-${reservation.code}'),
                tooltip: l10n.closeNotice,
                icon: Icon(Icons.close, color: foreground),
                onPressed: () => ref.read(activeReservationsProvider.notifier).remove(reservation.code),
              )
            : Icon(Icons.chevron_right, color: foreground),
        onTap: () => context.push('/reservation', extra: reservation),
      ),
    );
  }
}
