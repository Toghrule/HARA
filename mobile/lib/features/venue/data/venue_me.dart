/// Where the signed-in owner or waiter stands.
enum VenueStatus {
  pending,
  approved,
  rejected,

  /// Nothing on record for this account (for example, the owner removed it).
  none;

  static VenueStatus fromApi(String? value) => switch (value) {
        'Pending' => pending,
        'Approved' => approved,
        'Rejected' => rejected,
        _ => none,
      };
}

class VenueRestaurant {
  const VenueRestaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.discountPercent,
    this.imageUrl,
  });

  factory VenueRestaurant.fromJson(Map<String, dynamic> json) => VenueRestaurant(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
        imageUrl: json['imageUrl'] as String?,
      );

  final String id;
  final String name;
  final String address;
  final int discountPercent;
  final String? imageUrl;
}

/// The answer of `GET /api/venue/me`.
class VenueMe {
  const VenueMe({required this.isOwner, required this.status, this.fullName, this.restaurant, this.note});

  factory VenueMe.fromJson(Map<String, dynamic> json) => VenueMe(
        isOwner: json['role'] == 'Owner',
        status: VenueStatus.fromApi(json['status'] as String?),
        fullName: json['fullName'] as String?,
        restaurant: json['restaurant'] == null ? null : VenueRestaurant.fromJson(json['restaurant'] as Map<String, dynamic>),
        note: json['note'] as String?,
      );

  final bool isOwner;
  final VenueStatus status;
  final String? fullName;

  /// Present once approved.
  final VenueRestaurant? restaurant;

  /// The reason, when an owner's registration was declined.
  final String? note;
}
