import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/restaurant.dart';
import '../../data/restaurants_repository.dart';

final restaurantProvider = FutureProvider.autoDispose.family<Restaurant, String>((ref, id) {
  return ref.watch(restaurantsRepositoryProvider).getRestaurant(id);
});
