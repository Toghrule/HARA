class Reservation {
  const Reservation({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.discountPercent,
    required this.code,
    required this.durationMinutes,
    required this.expiresAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'] as String,
        restaurantId: json['restaurantId'] as String,
        restaurantName: json['restaurantName'] as String,
        discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
        code: json['code'] as String,
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );

  final String id;
  final String restaurantId;
  final String restaurantName;
  final int discountPercent;
  final String code;
  final int durationMinutes;
  final DateTime expiresAt;
}
