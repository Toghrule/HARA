import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/reservations/data/reservations_repository.dart';
import '../../features/venue/data/venue_repository.dart';
import '../l10n/locale_provider.dart';
import 'push_service.dart';

/// Tells the server which phone to notify: the restaurant person's phone about new requests, and a customer's
/// phone about the answer to their request. Registering is a convenience, so it never fails loudly: without
/// permission, a connection, or Firebase, the app simply relies on its own refreshing while it's open.
class PushRegistrar {
  PushRegistrar(this._ref);

  final Ref _ref;

  String? _venueToken;
  StreamSubscription<String>? _venueRefreshes;

  String get _language => _ref.read(localeProvider).languageCode;

  /// The signed-in, approved owner or waiter wants to hear about new requests. Safe to repeat (e.g. when the
  /// language changes, so the notification text follows it).
  Future<void> registerVenue() async {
    try {
      final service = _ref.read(pushServiceProvider);
      final token = await service.token();
      if (token == null) return;

      _venueToken = token;
      await _ref.read(venueRepositoryProvider).registerDevice(token, _language);

      _venueRefreshes ??= service.tokenRefreshes.listen((fresh) async {
        _venueToken = fresh;
        try {
          await _ref.read(venueRepositoryProvider).registerDevice(fresh, _language);
        } catch (_) {
          // Registered again the next time the screen opens.
        }
      });
    } catch (_) {
      // See above: notifications are optional.
    }
  }

  /// Must run while still signed in (the server checks who is asking): this phone stops getting the restaurant's
  /// notifications.
  Future<void> unregisterVenue() async {
    unawaited(_venueRefreshes?.cancel());
    _venueRefreshes = null;

    final token = _venueToken;
    _venueToken = null;
    if (token == null) return;

    try {
      await _ref.read(venueRepositoryProvider).unregisterDevice(token);
    } catch (_) {
      // The server forgets the phone anyway when Firebase says the token is dead, or when someone else signs in on it.
    }
  }

  /// A customer sent a request: this phone wants to hear the restaurant's answer.
  Future<void> registerReservation(String code) async {
    try {
      final token = await _ref.read(pushServiceProvider).token();
      if (token == null) return;

      await _ref.read(reservationsRepositoryProvider).registerDevice(code, token, _language);
    } catch (_) {
      // The reservation screen refreshes itself while it's open.
    }
  }
}

final pushRegistrarProvider = Provider<PushRegistrar>((ref) => PushRegistrar(ref));
