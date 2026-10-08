import '../../reservations/data/reservation_state.dart';

/// A customer's reservation as the restaurant sees it when confirming a code.
class VenueReservation {
  const VenueReservation({
    required this.id,
    required this.code,
    required this.phoneNumber,
    required this.durationMinutes,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    required this.discountPercent,
    this.redeemedAt,
  });

  factory VenueReservation.fromJson(Map<String, dynamic> json) => VenueReservation(
        id: json['id'] as String,
        code: json['code'] as String,
        phoneNumber: json['phoneNumber'] as String,
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        status: ReservationState.fromApi((json['status'] as num).toInt()),
        discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
        redeemedAt: json['redeemedAt'] == null ? null : DateTime.parse(json['redeemedAt'] as String),
      );

  final String id;
  final String code;
  final String phoneNumber;
  final int durationMinutes;
  final DateTime createdAt;
  final DateTime expiresAt;
  final ReservationState status;
  final int discountPercent;
  final DateTime? redeemedAt;

  /// What the reservation is now: the server may have said active a moment ago, but the window can close
  /// while the waiter is looking at it.
  ReservationState get effectiveStatus =>
      status == ReservationState.active && !expiresAt.isAfter(DateTime.now()) ? ReservationState.expired : status;

  /// Usable right now.
  bool get isUsable => effectiveStatus == ReservationState.active;
}

/// Whether a waiter may act for the restaurant yet.
enum MemberStatus {
  pending,
  approved,
  rejected;

  static MemberStatus fromApi(int value) => switch (value) {
        0 => pending,
        1 => approved,
        _ => rejected,
      };
}

/// A person on the restaurant's team, as the owner sees them.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isOwner,
    required this.status,
    this.phoneNumber,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        isOwner: (json['role'] as num).toInt() == 0,
        status: MemberStatus.fromApi((json['status'] as num).toInt()),
      );

  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final bool isOwner;
  final MemberStatus status;
}

enum ChangeRequestState {
  pending,
  approved,
  rejected;

  static ChangeRequestState fromApi(int value) => switch (value) {
        0 => pending,
        1 => approved,
        _ => rejected,
      };
}

/// An owner's request to change what the app shows about their restaurant. A field that is `null` is not
/// being changed.
class ChangeRequest {
  const ChangeRequest({
    required this.id,
    required this.status,
    required this.createdAt,
    this.name,
    this.address,
    this.phoneNumber,
    this.description,
    this.descriptionRu,
    this.descriptionEn,
    this.discountPercent,
    this.ownerNote,
    this.adminNote,
  });

  factory ChangeRequest.fromJson(Map<String, dynamic> json) => ChangeRequest(
        id: json['id'] as String,
        status: ChangeRequestState.fromApi((json['status'] as num).toInt()),
        createdAt: DateTime.parse(json['createdAt'] as String),
        name: json['name'] as String?,
        address: json['address'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        description: json['description'] as String?,
        descriptionRu: json['descriptionRu'] as String?,
        descriptionEn: json['descriptionEn'] as String?,
        discountPercent: (json['discountPercent'] as num?)?.toInt(),
        ownerNote: json['ownerNote'] as String?,
        adminNote: json['adminNote'] as String?,
      );

  final String id;
  final ChangeRequestState status;
  final DateTime createdAt;
  final String? name;
  final String? address;
  final String? phoneNumber;
  final String? description;
  final String? descriptionRu;
  final String? descriptionEn;
  final int? discountPercent;
  final String? ownerNote;
  final String? adminNote;

  /// The asked-for changes, one short line each, for the owner's list.
  List<String> get summary => [
        if (name != null) name!,
        if (address != null) address!,
        if (phoneNumber != null) phoneNumber!,
        if (discountPercent != null) '$discountPercent%',
        if (description != null) description!,
        if (descriptionRu != null) descriptionRu!,
        if (descriptionEn != null) descriptionEn!,
      ];
}
