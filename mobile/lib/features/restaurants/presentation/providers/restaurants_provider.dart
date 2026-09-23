import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/restaurant.dart';
import '../../data/restaurants_repository.dart';
import 'restaurant_sort_provider.dart';

final restaurantsProvider = FutureProvider.autoDispose<List<Restaurant>>((ref) {
  final sort = ref.watch(restaurantSortProvider);
  final repository = ref.watch(restaurantsRepositoryProvider);
  return repository.getRestaurants(sort);
});
