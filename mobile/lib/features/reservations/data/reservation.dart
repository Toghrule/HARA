import 'reservation_state.dart';

/// How long a reservation holds the table once the restaurant accepts it. The server accepts only this length.
const reservationHoldMinutes = 30;

/// A customer's reservation request, as the app keeps it. [expiresAt] is the deadline that applies now: while
/// the request waits ([ReservationState.pending]) it is when the restaurant's time to answer runs out; once the
/// restaurant accepts it, it is the end of the hold time.
class Reservation {
  const Reservation({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.discountPercent,
    required this.code,
    required this.durationMinutes,
    required this.expiresAt,
    this.status = ReservationState.active,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'] as String,
        restaurantId: json['restaurantId'] as String,
        restaurantName: json['restaurantName'] as String,
        discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
        code: json['code'] as String,
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        // Reservations saved before restaurants had to accept them have no status: they were accepted.
        status: ReservationState.fromApi((json['status'] as num?)?.toInt() ?? 0),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'discountPercent': discountPercent,
        'code': code,
        'durationMinutes': durationMinutes,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'status': status.index,
      };

  final String id;
  final String restaurantId;
  final String restaurantName;
  final int discountPercent;
  final String code;
  final int durationMinutes;
  final DateTime expiresAt;
  final ReservationState status;

  Reservation copyWith({ReservationState? status, DateTime? expiresAt}) => Reservation(
        id: id,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        discountPercent: discountPercent,
        code: code,
        durationMinutes: durationMinutes,
        expiresAt: expiresAt ?? this.expiresAt,
        status: status ?? this.status,
      );
}
