import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/restaurant_sort.dart';

class RestaurantSortNotifier extends Notifier<RestaurantSort> {
  @override
  RestaurantSort build() => RestaurantSort.nameAsc;

  void toggle() {
    state = state == RestaurantSort.nameAsc ? RestaurantSort.nameDesc : RestaurantSort.nameAsc;
  }
}

final restaurantSortProvider = NotifierProvider<RestaurantSortNotifier, RestaurantSort>(
  RestaurantSortNotifier.new,
);
