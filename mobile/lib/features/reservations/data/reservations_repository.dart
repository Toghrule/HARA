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

  /// Where the reservation stands and its current deadline, or `null` when the server no longer knows it.
  Future<ReservationStatusInfo?> getStatus(String code) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/reservations/$code/status');

      return ReservationStatusInfo(
        state: ReservationState.fromApi((response.data!['status'] as num).toInt()),
        expiresAt: DateTime.parse(response.data!['expiresAt'] as String),
        rating: (response.data!['rating'] as num?)?.toInt(),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// This phone should be notified of the restaurant's answer to the request with this code.
  Future<void> registerDevice(String code, String token, String language) async {
    await _apiClient.dio.post<void>('/api/reservations/$code/device', data: {'token': token, 'language': language});
  }

  /// After the restaurant confirmed the code: the customer's stars (1 to 5) for the restaurant. Once per phone number per restaurant.
  Future<void> rate(String code, int stars) async {
    await _apiClient.dio.post<void>('/api/reservations/$code/rating', data: {'stars': stars});
  }

  /// Gives up a reservation before it's used, which lets the same phone book again.
  Future<void> cancel(String code) async {
    await _apiClient.dio.post<void>('/api/reservations/$code/cancel');
  }
}

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  return ReservationsRepository(ref.watch(apiClientProvider));
});

/// The server's answer to "how is this reservation doing": its state, and the deadline that applies now (the
/// restaurant's time to answer while waiting; the end of the hold time once accepted).
class ReservationStatusInfo {
  const ReservationStatusInfo({required this.state, required this.expiresAt, this.rating});

  final ReservationState state;
  final DateTime expiresAt;

  /// The stars this phone already gave the restaurant, or `null` if it has not rated.
  final int? rating;
}
