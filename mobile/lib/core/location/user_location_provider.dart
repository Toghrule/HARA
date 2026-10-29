import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_service.dart';

class UserLocationState {
  const UserLocationState({this.position, this.access = LocationAccess.denied, this.asked = false, this.loaded = false});

  /// The phone's approximate position, once permission is given and it has been found.
  final UserPosition? position;
  final LocationAccess access;

  /// Whether the person has already been asked once (they are not asked again on their own).
  final bool asked;

  /// Whether the saved answer and the phone's permission have been read yet.
  final bool loaded;

  UserLocationState copyWith({UserPosition? position, LocationAccess? access, bool? asked, bool? loaded}) => UserLocationState(
        position: position ?? this.position,
        access: access ?? this.access,
        asked: asked ?? this.asked,
        loaded: loaded ?? this.loaded,
      );
}

/// Keeps the phone's position for sorting by distance. It asks for permission only once on its own, at first launch, after a
/// short explanation; after that only when the person picks "Nearest".
class UserLocationController extends StateNotifier<UserLocationState> {
  UserLocationController(this._service) : super(const UserLocationState()) {
    ready = _load();
  }

  static const _askedKey = 'location_asked';

  final LocationService _service;

  /// Completes once the saved answer and the phone's current permission are known.
  late final Future<void> ready;

  Future<void> _load() async {
    var asked = false;
    try {
      asked = (await SharedPreferences.getInstance()).getBool(_askedKey) ?? false;
    } catch (_) {
      // Treated as not asked yet.
    }

    final access = _service.isSupported ? await _service.access() : LocationAccess.denied;
    if (!mounted) return;
    state = state.copyWith(access: access, asked: asked, loaded: true);

    if (access == LocationAccess.granted) await refreshPosition();
  }

  /// Whether the explanation should be shown now: location is available, and the person was never asked.
  bool get shouldExplain => _service.isSupported && state.loaded && !state.asked && state.access == LocationAccess.denied;

  /// Remembers that the person has seen the question, whatever they answered.
  Future<void> markAsked() async {
    if (!mounted) return;
    state = state.copyWith(asked: true);
    try {
      await (await SharedPreferences.getInstance()).setBool(_askedKey, true);
    } catch (_) {
      // Asked again next time at worst.
    }
  }

  /// Asks the phone for permission (its own dialog) and, if given, finds the position.
  Future<LocationAccess> request() async {
    await markAsked();
    final access = await _service.request();
    if (!mounted) return access;
    state = state.copyWith(access: access);

    if (access == LocationAccess.granted) await refreshPosition();

    return access;
  }

  /// Looks for the position again (permission is already given).
  Future<void> refreshPosition() async {
    final position = await _service.position();
    if (!mounted || position == null) return;

    state = state.copyWith(position: position);
  }

  Future<void> openSettings() => _service.openSettings();
}

final userLocationProvider = StateNotifierProvider<UserLocationController, UserLocationState>(
  (ref) => UserLocationController(ref.watch(locationServiceProvider)),
);
