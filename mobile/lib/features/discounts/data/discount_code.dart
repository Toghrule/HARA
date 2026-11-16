import '../../reservations/data/reservation_state.dart';

/// A discount code the customer got at a restaurant that gives a discount. It can be confirmed by the restaurant for 6 hours; a device
/// gets one per restaurant per day.
class DiscountCode {
  const DiscountCode({
    required this.code,
    required this.restaurantId,
    required this.restaurantName,
    required this.discountPercent,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    this.redeemedAt,
  });

  factory DiscountCode.fromJson(Map<String, dynamic> json) => DiscountCode(
        code: json['code'] as String,
        restaurantId: json['restaurantId'] as String,
        restaurantName: json['restaurantName'] as String,
        discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        status: ReservationState.fromApi((json['status'] as num).toInt()),
        redeemedAt: json['redeemedAt'] == null ? null : DateTime.parse(json['redeemedAt'] as String),
      );

  final String code;
  final String restaurantId;
  final String restaurantName;
  final int discountPercent;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// As the server says: active, redeemed (the restaurant confirmed it) or expired.
  final ReservationState status;
  final DateTime? redeemedAt;

  /// Still valid on this phone's clock: the server may have said active a moment ago, but the six hours can run out meanwhile.
  bool get isUsable => status == ReservationState.active && expiresAt.isAfter(DateTime.now());

  bool get isRedeemed => status == ReservationState.redeemed;
}
