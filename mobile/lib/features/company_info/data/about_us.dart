import '../../../core/constants/app_constants.dart';

class AboutUs {
  const AboutUs({required this.companyName, required this.description, this.logoUrl});

  factory AboutUs.fromJson(Map<String, dynamic> json) => AboutUs(
        companyName: (json['companyName'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        logoUrl: json['logoUrl'] as String?,
      );

  final String companyName;
  final String description;
  final String? logoUrl;

  /// The API answers with blank fields until an admin has filled in the About Us page.
  bool get isEmpty => companyName.trim().isEmpty && description.trim().isEmpty;

  Uri? get logoUri => logoUrl == null || logoUrl!.trim().isEmpty ? null : AppConstants.resolveApiUrl(logoUrl!);
}
