import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/restaurant.dart';
import '../../data/restaurants_repository.dart';

/// This week's picks for the top of the home screen. Not a problem if they cannot be loaded: the home screen simply shows no row.
final featuredRestaurantsProvider = FutureProvider.autoDispose<List<Restaurant>>((ref) async {
  try {
    return await ref.watch(restaurantsRepositoryProvider).getFeatured();
  } catch (_) {
    return const [];
  }
});
