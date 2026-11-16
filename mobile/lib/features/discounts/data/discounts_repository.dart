import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import 'discount_code.dart';

/// What the app tells HARA about a customer's tap on a restaurant (counted for the admin, anonymously).
class RestaurantEvent {
  RestaurantEvent._();

  /// The restaurant's page was opened.
  static const view = 'view';

  /// The way to the restaurant was opened in maps.
  static const directions = 'directions';
}

/// The anonymous number of this phone: made once, kept on the phone, never tied to a person. It lets HARA give one discount code
/// per restaurant per day and count how many different phones looked at a restaurant. A reinstalled app gets a new one.
Future<String> loadDeviceId() async {
  const key = 'device_id';

  try {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(key);
    if (saved != null && saved.length >= 8) return saved;

    final random = Random.secure();
    final made = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    await preferences.setString(key, made);

    return made;
  } catch (_) {
    // Without storage the number is made again each time the app starts: still valid, just not remembered.
    final random = Random.secure();

    return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}

final deviceIdProvider = FutureProvider<String>((ref) => loadDeviceId());

class DiscountsRepository {
  DiscountsRepository(this._apiClient, this._deviceId);

  final ApiClient _apiClient;
  final Future<String> Function() _deviceId;

  /// The customer's code for [restaurantId]: a new one, or today's if they already took one (even when it is used or run out).
  Future<DiscountCode> getCode(String restaurantId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/restaurants/$restaurantId/discount-code',
      data: {'deviceId': await _deviceId()},
    );

    return DiscountCode.fromJson(response.data!);
  }

  /// Where a code stands now (still valid, confirmed by the restaurant, run out).
  Future<DiscountCode> getStatus(String code) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/discount-codes/$code');

    return DiscountCode.fromJson(response.data!);
  }

  /// Tells HARA about a tap, for the admin's numbers. Never throws: a failure here is nobody's problem.
  Future<void> recordEvent(String restaurantId, String type) async {
    try {
      await _apiClient.dio.post<void>('/api/restaurants/$restaurantId/events', data: {'type': type, 'deviceId': await _deviceId()});
    } catch (_) {
      // Counting is best effort.
    }
  }
}

final discountsRepositoryProvider = Provider<DiscountsRepository>((ref) => DiscountsRepository(ref.watch(apiClientProvider), loadDeviceId));
