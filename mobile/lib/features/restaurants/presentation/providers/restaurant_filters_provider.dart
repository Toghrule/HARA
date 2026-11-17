import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/restaurant_filters.dart';

class RestaurantFiltersNotifier extends Notifier<RestaurantFilters> {
  @override
  RestaurantFilters build() => const RestaurantFilters();

  void toggleOpenNow() => state = state.copyWith(openNow: !state.openNow);

  void setNearest(bool value) => state = state.copyWith(nearest: value);

  void setFavorites(bool value) => state = state.copyWith(favoritesOnly: value);

  void toggleFavorites() => state = state.copyWith(favoritesOnly: !state.favoritesOnly);

  /// Picks a cuisine; picking the one already chosen clears it.
  void toggleCuisine(String code) => state = state.copyWith(cuisine: state.cuisine == code ? null : code);

  /// Picks an area of Baku; picking the one already chosen clears it.
  void toggleDistrict(String code) => state = state.copyWith(district: state.district == code ? null : code);

  /// Removes everything that narrows the list (sorting by distance stays).
  void clearNarrowing() => state = RestaurantFilters(nearest: state.nearest);
}

final restaurantFiltersProvider = NotifierProvider<RestaurantFiltersNotifier, RestaurantFilters>(RestaurantFiltersNotifier.new);
