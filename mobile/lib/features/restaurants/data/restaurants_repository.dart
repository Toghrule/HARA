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

  Future<Restaurant> getRestaurant(String id) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/restaurants/$id');

    return Restaurant.fromJson(response.data!);
  }
}

final restaurantsRepositoryProvider = Provider<RestaurantsRepository>((ref) {
  return RestaurantsRepository(ref.watch(apiClientProvider));
});
