// Runs the app's real code against a real backend on localhost:5081 and checks that the two still agree: owner and
// waiter registration, the admin activating the owner, confirming a customer's code (and the customer's card seeing
// it), restaurant isolation, token renewal and replay protection, change requests and removing a waiter.
//
// It is NOT part of `flutter test` (it needs a backend and an EMPTY database, and it creates data). To run it:
//   1. create an empty throwaway database and apply the migrations to it (see HANDOFF.md, "Canlı test"),
//   2. start the API against it on port 5081 (ASPNETCORE_ENVIRONMENT=Development),
//   3. ADMIN_PW=<the AdminUser password from appsettings.Development.json> \
//        flutter test live_test/live_contract_test.dart --dart-define=API_BASE_URL=http://localhost:5081
// Never point it at your real database.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/auth/auth_controller.dart';
import 'package:hara/core/auth/auth_repository.dart';
import 'package:hara/core/auth/auth_session.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/reservations/data/reservation_state.dart';
import 'package:hara/features/reservations/data/reservations_repository.dart';
import 'package:hara/features/venue/data/venue_me.dart';
import 'package:hara/features/venue/data/venue_models.dart';
import 'package:hara/features/venue/data/venue_repository.dart';

import '../test/helpers/app_harness.dart';

const _base = 'http://localhost:5081';

void main() {
  test('the app talks to the real backend end to end', () async {
    HttpOverrides.global = null;
    final adminPassword = Platform.environment['ADMIN_PW']!;

    // --- admin (raw calls: the admin panel is not part of the mobile app) ---
    final adminDio = Dio(BaseOptions(baseUrl: _base));
    final adminLogin = await adminDio.post<Map<String, dynamic>>('/api/auth/login', data: {'email': 'admin@hara.local', 'password': adminPassword});
    adminDio.options.headers['Authorization'] = 'Bearer ${adminLogin.data!['token']}';

    // --- owner registers from the app ---
    final authRepo = AuthRepository(Dio(BaseOptions(baseUrl: _base)));
    final ownerSession = await authRepo.registerOwner(
      email: 'live.owner@cafe.az',
      password: 'Passw0rd1',
      fullName: 'Live Owner',
      restaurantName: 'ZZ Live Cafe',
      address: 'Baku, Live 1',
      description: 'Contract test',
    );
    expect(ownerSession.isOwner, isTrue);
    expect(ownerSession.refreshToken, isNotEmpty);

    final ownerAuth = AuthController(authRepo, MemorySessionStorage(), ownerSession);
    final owner = VenueRepository(ApiClient(tokens: ownerAuth));

    var me = await owner.getMe();
    expect(me.status, VenueStatus.pending);
    expect(me.isOwner, isTrue);
    expect(me.restaurant, isNull);

    // --- admin creates the restaurant from the registration ---
    final subs = await adminDio.get<List<dynamic>>('/api/admin/submissions');
    final submission = subs.data!.cast<Map<String, dynamic>>().firstWhere((s) => s['restaurantName'] == 'ZZ Live Cafe');
    expect(submission['hasOwnerAccount'], isTrue);
    final created = await adminDio.post<Map<String, dynamic>>('/api/admin/restaurants', data: {
      'name': 'ZZ Live Cafe',
      'description': 'old',
      'address': 'Baku, Live 1',
      'latitude': 40.4,
      'longitude': 49.8,
      'phoneNumber': null,
      'imageUrl': null,
      'discountPercent': 8,
      'fromSubmissionId': submission['id'],
    });
    final restaurantId = created.data!['id'] as String;

    me = await owner.getMe();
    expect(me.status, VenueStatus.approved);
    expect(me.restaurant?.name, 'ZZ Live Cafe');
    expect(me.restaurant?.discountPercent, 8);

    // --- a customer reserves with the real customer code ---
    final customer = ReservationsRepository(ApiClient());
    final reservation = await customer.create(restaurantId: restaurantId, phoneNumber: '+994501234567', durationMinutes: 30);
    expect(await customer.getStatus(reservation.code), ReservationState.active);

    // --- the owner looks the code up and confirms it ---
    final found = await owner.lookup(reservation.code.toLowerCase());
    expect(found.code, reservation.code);
    expect(found.phoneNumber, '+994501234567');
    expect(found.discountPercent, 8);
    expect(found.status, ReservationState.active);
    expect(found.isUsable, isTrue);

    expect((await owner.getReservations(status: ReservationState.active)).map((r) => r.code), contains(reservation.code));

    final confirmed = await owner.redeem(reservation.code);
    expect(confirmed.status, ReservationState.redeemed);
    expect(confirmed.redeemedAt, isNotNull);
    expect(await customer.getStatus(reservation.code), ReservationState.redeemed, reason: 'the customer card sees it');
    await expectLater(owner.redeem(reservation.code), throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 400)));
    expect((await owner.getReservations(status: ReservationState.redeemed)).map((r) => r.code), contains(reservation.code));

    // --- another restaurant's code is not found ---
    final other = await adminDio.post<Map<String, dynamic>>('/api/admin/restaurants', data: {
      'name': 'ZZ Other', 'description': null, 'address': 'Baku', 'latitude': 40.4, 'longitude': 49.8,
      'phoneNumber': null, 'imageUrl': null, 'discountPercent': 5,
    });
    final foreign = await customer.create(restaurantId: other.data!['id'] as String, phoneNumber: '+994507654321', durationMinutes: 30);
    await expectLater(owner.lookup(foreign.code), throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 404)));
    await expectLater(owner.redeem(foreign.code), throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 404)));
    expect(await customer.getStatus(foreign.code), ReservationState.active, reason: 'untouched');

    // --- a waiter registers; the owner approves ---
    final waiterSession = await authRepo.registerStaff(
      email: 'live.waiter@cafe.az',
      password: 'Passw0rd1',
      fullName: 'Live Waiter',
      restaurantId: restaurantId,
    );
    expect(waiterSession.isStaff, isTrue);
    final waiterAuth = AuthController(authRepo, MemorySessionStorage(), waiterSession);
    final waiter = VenueRepository(ApiClient(tokens: waiterAuth));

    expect((await waiter.getMe()).status, VenueStatus.pending);
    await expectLater(waiter.lookup(reservation.code), throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 403)));

    final team = await owner.getStaff();
    final pending = team.firstWhere((m) => m.status == MemberStatus.pending);
    expect(pending.fullName, 'Live Waiter');
    expect(pending.isOwner, isFalse);
    expect(team.any((m) => m.isOwner), isTrue);

    await waiter.getMe();
    await expectLater(waiter.getStaff(), throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 403)));
    await owner.approveStaff(pending.id);

    expect((await waiter.getMe()).status, VenueStatus.approved);
    expect((await waiter.getMe()).isOwner, isFalse);
    final waiterFind = await waiter.lookup(reservation.code);
    expect(waiterFind.status, ReservationState.redeemed);
    await expectLater(waiter.getStaff(), throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 403)), reason: 'owners only');

    // --- sessions renew themselves ---
    final expired = AuthSession(
      accessToken: 'expired-token',
      accessExpiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      refreshToken: ownerSession.refreshToken,
      roles: ownerSession.roles,
    );
    final storage = MemorySessionStorage(expired);
    final renewing = AuthController(authRepo, storage, expired);
    final viaRenewal = VenueRepository(ApiClient(tokens: renewing));
    expect((await viaRenewal.getMe()).status, VenueStatus.approved, reason: 'renewed before the request');
    expect(renewing.session?.refreshToken, isNot(ownerSession.refreshToken));
    expect(storage.saved?.refreshToken, renewing.session?.refreshToken);

    // the old refresh token has been used up: using it again is refused and signs the account out everywhere
    final replay = AuthController(authRepo, MemorySessionStorage(expired), expired);
    expect(await replay.validAccessToken(), isNull);
    expect(replay.session, isNull);

    // the replay ended every session: the renewed one can no longer be renewed either (its short-lived access
    // token keeps working until it expires, which is by design)
    expect(await renewing.refreshAccessToken(), isNull);
    expect(renewing.session, isNull);

    // --- change requests ---
    final freshOwnerSession = await authRepo.login(email: 'live.owner@cafe.az', password: 'Passw0rd1');
    final owner2 = VenueRepository(ApiClient(tokens: AuthController(authRepo, MemorySessionStorage(), freshOwnerSession)));

    await owner2.createChangeRequest(name: 'ZZ Live Cafe Deluxe', discountPercent: 12, descriptionEn: 'With a terrace', ownerNote: 'Renovated');
    final requests = await owner2.getChangeRequests();
    expect(requests.single.status, ChangeRequestState.pending);
    expect(requests.single.name, 'ZZ Live Cafe Deluxe');
    expect(requests.single.discountPercent, 12);
    expect(requests.single.address, isNull, reason: 'not asked for, not changed');
    expect(requests.single.summary, contains('ZZ Live Cafe Deluxe'));

    final adminList = await adminDio.get<List<dynamic>>('/api/admin/change-requests?status=0');
    await adminDio.patch<Map<String, dynamic>>('/api/admin/change-requests/${(adminList.data!.first as Map)['id']}/status', data: {'decision': 1, 'adminNote': 'Looks good'});

    final after = await owner2.getMe();
    expect(after.restaurant?.name, 'ZZ Live Cafe Deluxe');
    expect(after.restaurant?.discountPercent, 12);
    final answered = (await owner2.getChangeRequests()).single;
    expect(answered.status, ChangeRequestState.approved);
    expect(answered.adminNote, 'Looks good');

    // --- the owner removes the waiter ---
    final teamNow = await owner2.getStaff();
    await owner2.removeStaff(teamNow.firstWhere((m) => !m.isOwner).id);
    await expectLater(waiter.getMe().then((m) => m.status), completion(VenueStatus.none), reason: 'the removed waiter has nothing on record');
    await expectLater(waiter.lookup(reservation.code), throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 403)));
  });
}
