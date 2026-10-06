import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'about_us.dart';
import 'contact_info.dart';
import 'social_link.dart';

class CompanyInfoRepository {
  CompanyInfoRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AboutUs> getAboutUs() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/company-info/about');

    return AboutUs.fromJson(response.data!);
  }

  Future<List<ContactInfo>> getContacts() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/api/company-info/contacts');

    return (response.data ?? [])
        .map((json) => ContactInfo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<SocialLink>> getSocialLinks() async {
    final response = await _apiClient.dio.get<List<dynamic>>('/api/company-info/social-links');

    return (response.data ?? [])
        .map((json) => SocialLink.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

final companyInfoRepositoryProvider = Provider<CompanyInfoRepository>((ref) {
  return CompanyInfoRepository(ref.watch(apiClientProvider));
});
