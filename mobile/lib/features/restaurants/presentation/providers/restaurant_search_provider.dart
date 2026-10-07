import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The text the customer searched for, already trimmed. Empty means "show everything".
class RestaurantSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value.trim();
}

final restaurantSearchProvider = NotifierProvider<RestaurantSearchNotifier, String>(
  RestaurantSearchNotifier.new,
);
