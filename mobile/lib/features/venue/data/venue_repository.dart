import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'venue_me.dart';

/// The restaurant-side API. Every call needs a signed-in owner or waiter; the client adds their token.
class VenueRepository {
  VenueRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<VenueMe> getMe() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/venue/me');

    return VenueMe.fromJson(response.data!);
  }
}

final venueRepositoryProvider = Provider<VenueRepository>((ref) => VenueRepository(ref.watch(apiClientProvider)));
