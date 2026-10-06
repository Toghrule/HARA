import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class SubmissionsRepository {
  SubmissionsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Sends an "add my restaurant" request for the HARA team to review.
  /// Optional values should be passed as `null` when left empty.
  Future<void> create({
    required String restaurantName,
    String? address,
    String? phoneNumber,
    String? description,
    required String submitterName,
    String? submitterEmail,
    String? submitterPhoneNumber,
  }) async {
    await _apiClient.dio.post<void>(
      '/api/submissions',
      data: {
        'restaurantName': restaurantName,
        'address': address,
        'phoneNumber': phoneNumber,
        'description': description,
        'submitterName': submitterName,
        'submitterEmail': submitterEmail,
        'submitterPhoneNumber': submitterPhoneNumber,
      },
    );
  }
}

final submissionsRepositoryProvider = Provider<SubmissionsRepository>((ref) {
  return SubmissionsRepository(ref.watch(apiClientProvider));
});
