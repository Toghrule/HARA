import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'auth_session.dart';

/// Talks to the sign-in, registration and token endpoints. Uses its own plain client — no sign-in
/// header, no automatic refreshing — because these are the calls that create and renew the session.
class AuthRepository {
  AuthRepository([Dio? dio]) : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

  final Dio _dio;

  Future<AuthSession> login({required String email, required String password}) =>
      _session('/api/auth/login', {'email': email, 'password': password});

  /// Signs up a restaurant owner together with their restaurant. The admin reviews it; until then the
  /// owner can sign in but can't do anything for a restaurant.
  Future<AuthSession> registerOwner({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    required String restaurantName,
    required String address,
    String? restaurantPhoneNumber,
    String? description,
  }) =>
      _session('/api/auth/register-owner', {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'restaurantName': restaurantName,
        'address': address,
        'restaurantPhoneNumber': restaurantPhoneNumber,
        'description': description,
      });

  /// Signs up a waiter for an existing restaurant. The restaurant's owner has to approve them.
  Future<AuthSession> registerStaff({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    required String restaurantId,
  }) =>
      _session('/api/auth/register-staff', {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'restaurantId': restaurantId,
      });

  /// Trades a refresh token for a new session, or `null` when the server no longer accepts it (the person
  /// has to sign in again). Any other failure — no connection, server trouble — is thrown, because it says
  /// nothing about whether the refresh token is still good.
  Future<AuthSession?> refresh(String refreshToken) async {
    try {
      return await _session('/api/auth/refresh', {'refreshToken': refreshToken});
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<void>('/api/auth/logout', data: {'refreshToken': refreshToken});
  }

  Future<AuthSession> _session(String path, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: body);

    return AuthSession.fromApi(response.data!);
  }
}
