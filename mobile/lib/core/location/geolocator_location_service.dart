import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

/// The phone's location through the `geolocator` plugin. Asks for approximate location only (enough to sort restaurants
/// by distance), and never throws: any trouble means "no position".
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  bool get isSupported => true;

  LocationAccess _from(LocationPermission permission) => switch (permission) {
        LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        _ => LocationAccess.denied,
      };

  @override
  Future<LocationAccess> access() async {
    try {
      final access = _from(await Geolocator.checkPermission());
      if (access == LocationAccess.granted && !await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;

      return access;
    } catch (_) {
      return LocationAccess.denied;
    }
  }

  @override
  Future<LocationAccess> request() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      final access = _from(permission);
      if (access == LocationAccess.granted && !await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;

      return access;
    } catch (_) {
      return LocationAccess.denied;
    }
  }

  @override
  Future<UserPosition?> position() async {
    try {
      // Low accuracy: a few hundred metres to a couple of kilometres is plenty here, and it is quick and easy on the battery.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 10)),
      );

      return UserPosition(latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();

        return last == null ? null : UserPosition(latitude: last.latitude, longitude: last.longitude);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<void> openSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {
      // Nothing more to do.
    }
  }
}
