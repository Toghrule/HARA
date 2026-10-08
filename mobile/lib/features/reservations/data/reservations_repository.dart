import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'reservation.dart';
import 'reservation_state.dart';

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

  /// Whether the code can still be used, or `null` when the server no longer knows it.
  Future<ReservationState?> getStatus(String code) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/reservations/$code/status');

      return ReservationState.fromApi((response.data!['status'] as num).toInt());
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Gives up a reservation before it's used, which lets the same phone book again.
  Future<void> cancel(String code) async {
    await _apiClient.dio.post<void>('/api/reservations/$code/cancel');
  }
}

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  return ReservationsRepository(ref.watch(apiClientProvider));
});
