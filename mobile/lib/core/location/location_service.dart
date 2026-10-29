import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the phone is, roughly. Only used to sort restaurants by distance and to show how far they are.
class UserPosition {
  const UserPosition({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Whether the app may use the phone's location.
enum LocationAccess {
  granted,

  /// Not allowed (yet): the person can still be asked.
  denied,

  /// Refused with "don't ask again": only the phone's settings can change it now.
  deniedForever,

  /// The phone's location switch is off.
  serviceOff,
}

/// The phone's location. The real one is [GeolocatorLocationService]; tests and platforms without it use
/// [NoLocationService], which never asks for anything.
abstract class LocationService {
  /// Whether this build can use location at all. When it cannot, the app does not offer it.
  bool get isSupported;

  /// What the app is allowed to do right now, without asking.
  Future<LocationAccess> access();

  /// Asks the person for permission (the phone's own dialog), and returns the answer.
  Future<LocationAccess> request();

  /// The phone's approximate position, or `null` if it cannot be found.
  Future<UserPosition?> position();

  /// Opens the phone's settings for this app, where a refusal can be undone.
  Future<void> openSettings();
}

class NoLocationService implements LocationService {
  const NoLocationService();

  @override
  bool get isSupported => false;

  @override
  Future<LocationAccess> access() async => LocationAccess.denied;

  @override
  Future<LocationAccess> request() async => LocationAccess.denied;

  @override
  Future<UserPosition?> position() async => null;

  @override
  Future<void> openSettings() async {}
}

final locationServiceProvider = Provider<LocationService>((ref) => const NoLocationService());
