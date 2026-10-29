import '../../../core/constants/app_constants.dart';
import 'opening_hours.dart';

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
    this.openingHours = const [],
    this.availability = Availability.open,
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
        openingHours: [
          for (final day in (json['openingHours'] as List<dynamic>?) ?? const []) DayHours.fromJson(day as Map<String, dynamic>),
        ],
        availability: json['availability'] == null
            ? Availability.open
            : Availability.fromJson(json['availability'] as Map<String, dynamic>),
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

  /// The hours the owner set, one entry per weekday; empty when none were set (always open).
  final List<DayHours> openingHours;

  /// Whether a table can be requested right now.
  final Availability availability;

  /// Full URL of the cover image, or `null` if none was uploaded.
  Uri? get imageUri => imageUrl == null ? null : AppConstants.resolveApiUrl(imageUrl!);

  /// Admins start new restaurants at 0,0 ("null island"), which means "not set yet".
  bool get hasCoordinates => !(latitude == 0 && longitude == 0);
}
