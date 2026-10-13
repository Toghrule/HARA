import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/reservation.dart';
import '../../data/reservation_state.dart';
import '../../data/reservations_repository.dart';

/// The customer's reservations that are still going, kept on this device so the code can be shown again at
/// any time, not just right after booking: requests waiting for the restaurant, and accepted ones with their
/// hold timer. A request the restaurant declined, or never answered, stays in the list as a notice until the
/// customer closes it, so they are told what happened. There are no accounts, so this is the only place the
/// code lives: clearing the app's data (or using another device) loses it.
class ActiveReservations extends StateNotifier<List<Reservation>> {
  ActiveReservations(this._repository) : super(const []) {
    _ready = _load();
  }

  static const _preferenceKey = 'active_reservations';

  final ReservationsRepository Function() _repository;

  late final Future<void> _ready;

  /// Whether a saved reservation is still worth keeping after a restart: going, and its deadline not passed.
  /// (Notices about declined or unanswered requests were shown in the run they happened in.)
  static bool _isRunning(Reservation reservation) =>
      reservation.status.isInProgress && reservation.expiresAt.isAfter(DateTime.now());

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_preferenceKey);
      if (raw == null) return;

      final saved = (jsonDecode(raw) as List)
          .map((json) => Reservation.fromJson(json as Map<String, dynamic>))
          .where(_isRunning)
          .toList();
      if (mounted) state = saved;
    } catch (_) {
      // Unreadable or unavailable storage: start with nothing rather than failing the app.
    }
  }

  Future<void> _save() async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        _preferenceKey,
        jsonEncode(state.map((reservation) => reservation.toJson()).toList()),
      );
    } catch (_) {
      // The reservation still shows for this session.
    }
  }

  Future<void> add(Reservation reservation) async {
    await _ready;
    if (!mounted) return;

    state = [...state.where((existing) => existing.code != reservation.code), reservation];
    await _save();
  }

  /// Forgets a reservation once it has ended, been cancelled, or the customer closed its notice.
  Future<void> remove(String code) async {
    await _ready;
    if (!mounted || !state.any((reservation) => reservation.code == code)) return;

    state = state.where((reservation) => reservation.code != code).toList();
    await _save();
  }

  /// Replaces what is kept about a reservation (its state and deadline), if it is still kept.
  Future<void> _update(Reservation updated) async {
    if (!mounted || !state.any((reservation) => reservation.code == updated.code)) return;

    state = [for (final reservation in state) reservation.code == updated.code ? updated : reservation];
    await _save();
  }

  /// The deadline on this phone's clock has passed. A request nobody answered becomes a notice for the customer;
  /// an accepted reservation whose hold time ran out is simply over.
  Future<void> deadlinePassed(String code) async {
    await _ready;
    final reservation = state.where((kept) => kept.code == code).firstOrNull;
    if (reservation == null) return;

    if (reservation.status == ReservationState.pending) {
      await _update(reservation.copyWith(status: ReservationState.unanswered));
    } else if (reservation.status == ReservationState.active) {
      await remove(code);
    }
  }

  /// Asks the server about each reservation still going and brings the saved copy up to date:
  /// the restaurant accepted a request (the hold timer now runs from then, so the deadline changes), declined
  /// it, never answered, or the code was used or cancelled. A reservation whose status can't be fetched (no
  /// connection, server trouble) is left as it is, since not knowing is no reason to take a valid code away.
  Future<void> refresh() async {
    await _ready;
    if (!mounted) return;

    final repository = _repository();
    for (final reservation in List.of(state)) {
      if (!reservation.status.isInProgress) continue;

      try {
        final info = await repository.getStatus(reservation.code);
        if (!mounted) return;

        if (info == null) {
          await remove(reservation.code);
          continue;
        }

        switch (info.state) {
          case ReservationState.pending || ReservationState.active:
            if (info.state != reservation.status || info.expiresAt != reservation.expiresAt) {
              await _update(reservation.copyWith(status: info.state, expiresAt: info.expiresAt));
            }
          case ReservationState.declined || ReservationState.unanswered:
            await _update(reservation.copyWith(status: info.state));
          case ReservationState.redeemed || ReservationState.cancelled || ReservationState.expired:
            await remove(reservation.code);
        }
      } catch (_) {
        // Keep it and try again on the next check.
      }
      if (!mounted) return;
    }
  }
}

final activeReservationsProvider = StateNotifierProvider<ActiveReservations, List<Reservation>>(
  (ref) => ActiveReservations(() => ref.read(reservationsRepositoryProvider)),
);
