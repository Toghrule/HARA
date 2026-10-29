/// One weekday's opening hours. [day] counts like the server: 0 = Sunday ... 6 = Saturday. Times are "HH:mm"
/// in Azerbaijan time. A closing time at or before the opening time means after midnight; equal times mean open
/// all day.
class DayHours {
  const DayHours({required this.day, required this.isClosed, this.opens, this.closes});

  factory DayHours.fromJson(Map<String, dynamic> json) => DayHours(
        day: (json['day'] as num).toInt(),
        isClosed: json['isClosed'] as bool,
        opens: json['opens'] as String?,
        closes: json['closes'] as String?,
      );

  final int day;
  final bool isClosed;
  final String? opens;
  final String? closes;

  Map<String, Object?> toJson() => {'day': day, 'isClosed': isClosed, if (!isClosed) 'opens': opens, if (!isClosed) 'closes': closes};

  /// Opening and closing at the same time: open the whole day.
  bool get isAllDay => !isClosed && opens == closes;
}

/// Why a restaurant can or cannot be asked for a table right now.
enum AvailabilityReason {
  open,

  /// Open, but closing so soon that it takes no more requests.
  closingSoon,
  closed;

  static AvailabilityReason fromApi(int value) => switch (value) {
        1 => closingSoon,
        2 => closed,
        _ => open,
      };
}

/// Whether a table can be requested at a restaurant right now (as of when the app asked).
class Availability {
  const Availability({
    required this.acceptingRequests,
    required this.reason,
    this.closesAt,
    this.nextOpensInDays,
    this.nextOpensDay,
    this.nextOpensAt,
  });

  factory Availability.fromJson(Map<String, dynamic> json) => Availability(
        acceptingRequests: json['acceptingRequests'] as bool,
        reason: AvailabilityReason.fromApi((json['reason'] as num).toInt()),
        closesAt: json['closesAt'] as String?,
        nextOpensInDays: (json['nextOpensInDays'] as num?)?.toInt(),
        nextOpensDay: (json['nextOpensDay'] as num?)?.toInt(),
        nextOpensAt: json['nextOpensAt'] as String?,
      );

  /// A restaurant that has set no hours, or an older server that does not say: taken as open.
  static const open = Availability(acceptingRequests: true, reason: AvailabilityReason.open);

  final bool acceptingRequests;
  final AvailabilityReason reason;

  /// While open: the closing time, "HH:mm".
  final String? closesAt;

  /// While closed: 0 if it opens later today, 1 tomorrow, and so on.
  final int? nextOpensInDays;

  /// While closed: the weekday it opens next (0 = Sunday).
  final int? nextOpensDay;

  /// While closed: the time it opens next, "HH:mm".
  final String? nextOpensAt;
}
