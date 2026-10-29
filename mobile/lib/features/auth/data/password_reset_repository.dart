import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/password_reset_storage.dart';
import '../../../core/network/api_client.dart';

/// Where an owner's reset request stands (as the server counts: 0 waiting, 1 approved, 2 declined, 3 done, 4 out of time).
enum PasswordResetState {
  pending,
  approved,
  rejected,
  completed,
  expired;

  static PasswordResetState fromApi(int value) => switch (value) {
        1 => approved,
        2 => rejected,
        3 => completed,
        4 => expired,
        _ => pending,
      };
}

/// The password-reset calls. Anyone can make them (the owner cannot sign in), so none carries a token; the secret in the
/// ticket is what ties them to the phone that asked.
class PasswordResetRepository {
  PasswordResetRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Asks HARA to allow a new password for the owner with this email. The answer is the same for every email, so it
  /// never reveals who has an account.
  Future<PasswordResetTicket> request(String email) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>('/api/auth/password-reset/request', data: {'email': email});

    return PasswordResetTicket(
      requestId: response.data!['requestId'] as String,
      secret: response.data!['secret'] as String,
      email: email,
    );
  }

  Future<PasswordResetState> status(PasswordResetTicket ticket) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/api/auth/password-reset/status',
      data: {'requestId': ticket.requestId, 'secret': ticket.secret},
    );

    return PasswordResetState.fromApi((response.data!['status'] as num).toInt());
  }

  /// Sets the new password. Only works while the request is approved.
  Future<void> complete(PasswordResetTicket ticket, String newPassword) async {
    await _apiClient.dio.post<void>(
      '/api/auth/password-reset/complete',
      data: {'requestId': ticket.requestId, 'secret': ticket.secret, 'newPassword': newPassword},
    );
  }
}

final passwordResetRepositoryProvider = Provider<PasswordResetRepository>((ref) => PasswordResetRepository(ref.watch(apiClientProvider)));
