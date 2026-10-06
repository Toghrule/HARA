import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'reservation.dart';

class ReservationsRepository {
  ReservationsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Reservation> create({
    required String restaurantId,
    required String phoneNumber,
    required int durationMinutes,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/reservations',
      data: {
        'restaurantId': restaurantId,
        'phoneNumber': phoneNumber,
        'durationMinutes': durationMinutes,
      },
    );

    return Reservation.fromJson(response.data!);
  }

  /// Gives up a reservation before it's used, which lets the same phone book again.
  Future<void> cancel(String code) async {
    await _apiClient.dio.post<void>('/api/reservations/$code/cancel');
  }
}

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  return ReservationsRepository(ref.watch(apiClientProvider));
});
