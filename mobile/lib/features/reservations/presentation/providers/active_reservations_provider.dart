import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/reservation.dart';
import '../../data/reservation_state.dart';
import '../../data/reservations_repository.dart';

/// The customer's reservations that are still running, kept on this device so the code can be
/// shown again at any time, not just right after booking. There are no accounts, so this is the
/// only place the code lives: clearing the app's data (or using another device) loses it.
class ActiveReservations extends StateNotifier<List<Reservation>> {
  ActiveReservations(this._repository) : super(const []) {
    _ready = _load();
  }

  static const _preferenceKey = 'active_reservations';

  final ReservationsRepository Function() _repository;

  late final Future<void> _ready;

  static bool _isRunning(Reservation reservation) => reservation.expiresAt.isAfter(DateTime.now());

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

  /// Forgets a reservation once it has ended or been cancelled.
  Future<void> remove(String code) async {
    await _ready;
    if (!mounted || !state.any((reservation) => reservation.code == code)) return;

    state = state.where((reservation) => reservation.code != code).toList();
    await _save();
  }

  /// Asks the server about each kept reservation and forgets the ones that are no longer usable:
  /// the venue marked the code as used, it was cancelled, or the server doesn't know it any more.
  /// A reservation whose status can't be fetched (no connection, server trouble) is kept, since not
  /// knowing is no reason to take a valid code away from the customer.
  Future<void> refresh() async {
    await _ready;
    if (!mounted) return;

    final repository = _repository();
    for (final reservation in List.of(state)) {
      try {
        final status = await repository.getStatus(reservation.code);
        if (status != ReservationState.active) await remove(reservation.code);
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
