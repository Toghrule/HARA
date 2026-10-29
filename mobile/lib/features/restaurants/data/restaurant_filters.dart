import 'dart:math' as math;

import '../../../core/location/location_service.dart';

/// The kinds of cuisine a restaurant can be filed under: the codes the server knows, in the order the filter shows them.
const cuisineCodes = [
  'azerbaijani',
  'kebab',
  'european',
  'italian',
  'turkish',
  'georgian',
  'asian',
  'seafood',
  'fastfood',
  'pizza',
  'cafe',
  'dessert',
];

/// What the customer narrowed the list down to. Only what the server is asked about is here; sorting by distance is part of it.
class RestaurantFilters {
  const RestaurantFilters({this.openNow = false, this.nearest = false, this.favoritesOnly = false, this.cuisine});

  final bool openNow;

  /// Sort by distance from the phone's position instead of by name.
  final bool nearest;

  /// Only the restaurants the customer marked with a heart.
  final bool favoritesOnly;

  /// One of [cuisineCodes], or `null` for any.
  final String? cuisine;

  /// Whether anything is narrowing the list (sorting by distance does not narrow it).
  bool get narrows => openNow || favoritesOnly || cuisine != null;

  RestaurantFilters copyWith({bool? openNow, bool? nearest, bool? favoritesOnly, Object? cuisine = _keep}) => RestaurantFilters(
        openNow: openNow ?? this.openNow,
        nearest: nearest ?? this.nearest,
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
        cuisine: identical(cuisine, _keep) ? this.cuisine : cuisine as String?,
      );

  static const _keep = Object();
}

/// What is sent to the server with a list request besides the sort and the search.
class RestaurantListQuery {
  const RestaurantListQuery({this.openNow = false, this.cuisine, this.latitude, this.longitude, this.ids});

  final bool openNow;
  final String? cuisine;

  /// The phone's position, sent only when sorting by distance.
  final double? latitude;
  final double? longitude;

  /// Only these restaurants (the favourites).
  final List<String>? ids;
}

/// Straight-line distance in kilometres between the phone and a restaurant (Haversine).
double distanceKm(UserPosition from, double latitude, double longitude) {
  const earthRadiusKm = 6371.0;
  double radians(double degrees) => degrees * math.pi / 180;

  final dLat = radians(latitude - from.latitude);
  final dLon = radians(longitude - from.longitude);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(radians(from.latitude)) * math.cos(radians(latitude)) * math.pow(math.sin(dLon / 2), 2);

  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}
