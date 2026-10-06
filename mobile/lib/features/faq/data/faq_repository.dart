import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'faq_item.dart';

class FaqRepository {
  FaqRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Active questions, already in the order the admin arranged them.
  Future<List<FaqItem>> getFaqItems() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/api/faq');

    return (response.data ?? [])
        .map((json) => FaqItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

final faqRepositoryProvider = Provider<FaqRepository>((ref) {
  return FaqRepository(ref.watch(apiClientProvider));
});
