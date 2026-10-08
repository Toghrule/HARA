import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/reservation.dart';
import '../providers/active_reservations_provider.dart';

/// A card per running reservation at the top of the restaurant list, so the customer can open
/// their code again at any time. A card disappears by itself when its time is up, and also when the
/// server says the code was used or cancelled — checked when the list opens, when the app comes back
/// to the foreground and every [_checkInterval] while it stays open.
class ActiveReservationsBanner extends ConsumerStatefulWidget {
  const ActiveReservationsBanner({super.key});

  @override
  ConsumerState<ActiveReservationsBanner> createState() => _ActiveReservationsBannerState();
}

class _ActiveReservationsBannerState extends ConsumerState<ActiveReservationsBanner>
    with WidgetsBindingObserver {
  static const _checkInterval = Duration(seconds: 60);

  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    _checkTimer = Timer.periodic(_checkInterval, (_) => _check());
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
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _computeRemaining() {
    final remaining = widget.reservation.expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _tick() {
    final remaining = _computeRemaining();
    if (remaining == Duration.zero) {
      _timer?.cancel();
      ref.read(activeReservationsProvider.notifier).remove(widget.reservation.code);
      return;
    }
    if (remaining != _remaining) setState(() => _remaining = remaining);
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reservation = widget.reservation;
    final theme = Theme.of(context);
    final countdown = '${_two(_remaining.inMinutes)}:${_two(_remaining.inSeconds.remainder(60))}';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: theme.colorScheme.primaryContainer,
      child: ListTile(
        leading: Icon(Icons.confirmation_number_outlined, color: theme.colorScheme.onPrimaryContainer),
        title: Text(
          '${l10n.yourReservation}: ${reservation.restaurantName}',
          style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onPrimaryContainer),
        ),
        subtitle: Text(
          l10n.activeReservationSubtitle(reservation.code, countdown),
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onPrimaryContainer),
        onTap: () => context.push('/reservation', extra: reservation),
      ),
    );
  }
}
