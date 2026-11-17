import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/restaurant_filters.dart';
import '../../data/restaurants_repository.dart';

/// The areas of Baku that have restaurants, for the "Ərazi" chips. If they cannot be loaded there are simply no chips.
final areasProvider = FutureProvider.autoDispose<List<AreaCount>>((ref) async {
  try {
    return await ref.watch(restaurantsRepositoryProvider).getAreas();
  } catch (_) {
    return const [];
  }
});
