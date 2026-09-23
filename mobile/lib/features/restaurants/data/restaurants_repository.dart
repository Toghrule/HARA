import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'restaurant.dart';
import 'restaurant_sort.dart';

class RestaurantsRepository {
  RestaurantsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Restaurant>> getRestaurants(RestaurantSort sort) async {
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/restaurants',
      queryParameters: {'sort': sort.queryValue},
    );

    return (response.data ?? [])
        .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

final restaurantsRepositoryProvider = Provider<RestaurantsRepository>((ref) {
  return RestaurantsRepository(ref.watch(apiClientProvider));
});
