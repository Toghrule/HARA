import 'package:dio/dio.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/reservations/data/reservation_state.dart';
import 'package:hara/features/venue/data/venue_me.dart';
import 'package:hara/features/venue/data/venue_models.dart';
import 'package:hara/features/venue/data/venue_repository.dart';

VenueMe approvedOwner() => const VenueMe(
      isOwner: true,
      status: VenueStatus.approved,
      fullName: 'Anar Aliyev',
      restaurant: VenueRestaurant(id: 'rest-1', name: 'Cafe One', address: 'Baku, Nizami 1', discountPercent: 10),
    );

VenueMe approvedStaff() => const VenueMe(
      isOwner: false,
      status: VenueStatus.approved,
      fullName: 'Waiter Wali',
      restaurant: VenueRestaurant(id: 'rest-1', name: 'Cafe One', address: 'Baku, Nizami 1', discountPercent: 10),
    );

VenueMe pendingOwner() => const VenueMe(isOwner: true, status: VenueStatus.pending, fullName: 'Anar Aliyev');

VenueMe pendingStaff() => const VenueMe(isOwner: false, status: VenueStatus.pending, fullName: 'Waiter Wali');

VenueMe rejectedOwner({String? note}) =>
    VenueMe(isOwner: true, status: VenueStatus.rejected, fullName: 'Anar Aliyev', note: note);

VenueMe noVenue() => const VenueMe(isOwner: false, status: VenueStatus.none);

VenueReservation reservationOf(
  String code, {
  ReservationState status = ReservationState.active,
  Duration expiresIn = const Duration(minutes: 20),
  int discountPercent = 10,
  String phone = '+994501112233',
}) =>
    VenueReservation(
      id: 'id-$code',
      code: code,
      phoneNumber: phone,
      durationMinutes: 30,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      expiresAt: DateTime.now().add(expiresIn),
      status: status,
      discountPercent: discountPercent,
    );

StaffMember staffOf(String id, String name, {MemberStatus status = MemberStatus.approved, bool owner = false, String? phone}) =>
    StaffMember(id: id, fullName: name, email: '$id@cafe.az', isOwner: owner, status: status, phoneNumber: phone);

DioException serverFailure(int status, [Object? data]) {
  final options = RequestOptions(path: '/x');

  return DioException(requestOptions: options, response: Response(requestOptions: options, statusCode: status, data: data));
}

/// A fake restaurant-side API: answers from lists a test sets up, and remembers what the app asked for.
class FakeVenueRepository extends VenueRepository {
  FakeVenueRepository({required this.me}) : super(ApiClient());

  VenueMe me;
  int meCalls = 0;
  Object? meError;

  /// Reservations of "this restaurant"; a code that is not here is a 404, like on the server.
  final Map<String, VenueReservation> reservations = {};
  final List<String> lookups = [];
  final List<String> redeemed = [];
  Object? redeemError;

  List<StaffMember> staff = [];
  final List<String> approved = [];
  final List<String> rejected = [];
  final List<String> removed = [];

  List<ChangeRequest> changeRequests = [];
  final List<Map<String, Object?>> createdRequests = [];
  Object? createRequestError;

  @override
  Future<VenueMe> getMe() async {
    meCalls++;
    if (meError != null) throw meError!;

    return me;
  }

  @override
  Future<List<VenueReservation>> getReservations({ReservationState? status}) async =>
      reservations.values.where((r) => status == null || r.effectiveStatus == status).toList();

  @override
  Future<VenueReservation> lookup(String code) async {
    lookups.add(code);

    return reservations[code] ?? (throw serverFailure(404));
  }

  @override
  Future<VenueReservation> redeem(String code) async {
    if (redeemError != null) throw redeemError!;
    redeemed.add(code);
    final done = VenueReservation(
      id: reservations[code]!.id,
      code: code,
      phoneNumber: reservations[code]!.phoneNumber,
      durationMinutes: 30,
      createdAt: reservations[code]!.createdAt,
      expiresAt: reservations[code]!.expiresAt,
      status: ReservationState.redeemed,
      discountPercent: reservations[code]!.discountPercent,
      redeemedAt: DateTime.now(),
    );
    reservations[code] = done;

    return done;
  }

  @override
  Future<List<StaffMember>> getStaff() async => List.of(staff);

  @override
  Future<void> approveStaff(String id) async {
    approved.add(id);
    staff = [
      for (final member in staff)
        if (member.id == id) staffOf(id, member.fullName, status: MemberStatus.approved) else member,
    ];
  }

  @override
  Future<void> rejectStaff(String id) async {
    rejected.add(id);
    staff = [
      for (final member in staff)
        if (member.id == id) staffOf(id, member.fullName, status: MemberStatus.rejected) else member,
    ];
  }

  @override
  Future<void> removeStaff(String id) async {
    removed.add(id);
    staff = staff.where((member) => member.id != id).toList();
  }

  @override
  Future<List<ChangeRequest>> getChangeRequests() async => List.of(changeRequests);

  @override
  Future<void> createChangeRequest({
    String? name,
    String? address,
    String? phoneNumber,
    String? description,
    String? descriptionRu,
    String? descriptionEn,
    int? discountPercent,
    String? ownerNote,
  }) async {
    if (createRequestError != null) throw createRequestError!;

    createdRequests.add({
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'description': description,
      'descriptionRu': descriptionRu,
      'descriptionEn': descriptionEn,
      'discountPercent': discountPercent,
      'ownerNote': ownerNote,
    });
    changeRequests = [
      ChangeRequest(
        id: 'cr-${createdRequests.length}',
        status: ChangeRequestState.pending,
        createdAt: DateTime.now(),
        name: name,
        discountPercent: discountPercent,
      ),
      ...changeRequests,
    ];
  }
}

extension DioExceptionWithoutResponse on DioException {
  /// The same error as if the server had not answered at all.
  DioException copyWithoutResponse() => DioException(requestOptions: requestOptions);
}
