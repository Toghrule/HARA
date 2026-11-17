import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'restaurant.dart';
import 'restaurant_filters.dart';
import 'restaurant_sort.dart';

class RestaurantsRepository {
  RestaurantsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// One page of active restaurants. A page shorter than [pageSize] is the last one.
  Future<List<Restaurant>> getRestaurants({
    RestaurantSort sort = RestaurantSort.nameAsc,
    String search = '',
    int page = 1,
    int pageSize = 20,
    RestaurantListQuery query = const RestaurantListQuery(),
  }) async {
    final term = search.trim();
    final response = await _apiClient.dio.get<List<dynamic>>(
      '/api/restaurants',
      queryParameters: {
        'sort': sort.queryValue,
        if (term.isNotEmpty) 'search': term,
        'page': page,
        'pageSize': pageSize,
        if (query.openNow) 'openNow': true,
        if (query.cuisine != null) 'cuisine': query.cuisine,
        if (query.district != null) 'district': query.district,
        if (query.latitude != null && query.longitude != null) ...{'lat': query.latitude, 'lng': query.longitude},
        if (query.ids != null) 'ids': query.ids!.join(','),
      },
    );

    return (response.data ?? [])
        .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// The areas of Baku that have restaurants, the busiest first (for the area chips).
  Future<List<AreaCount>> getAreas() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/api/restaurants/areas');

    return (response.data ?? []).map((json) => AreaCount.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// This week's picks: the places that took a turn at the top of the app, whatever the position or the filters.
  Future<List<Restaurant>> getFeatured() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/api/restaurants/featured');

    return (response.data ?? []).map((json) => Restaurant.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Restaurant> getRestaurant(String id) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/restaurants/$id');

    return Restaurant.fromJson(response.data!);
  }
}

final restaurantsRepositoryProvider = Provider<RestaurantsRepository>((ref) {
  return RestaurantsRepository(ref.watch(apiClientProvider));
});
