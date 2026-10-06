import '../../../core/constants/app_constants.dart';

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.discountPercent = 0,
    this.description,
    this.phoneNumber,
    this.imageUrl,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
        description: json['description'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        imageUrl: json['imageUrl'] as String?,
      );

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int discountPercent;
  final String? description;
  final String? phoneNumber;
  final String? imageUrl;

  /// Full URL of the cover image, or `null` if none was uploaded.
  Uri? get imageUri => imageUrl == null ? null : AppConstants.resolveApiUrl(imageUrl!);

  /// Admins start new restaurants at 0,0 ("null island"), which means "not set yet".
  bool get hasCoordinates => !(latitude == 0 && longitude == 0);
}
