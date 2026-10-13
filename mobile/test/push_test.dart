import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/l10n/locale_provider.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/core/push/push_registrar.dart';
import 'package:hara/core/push/push_service.dart';
import 'package:hara/features/reservations/data/reservation_state.dart';
import 'package:hara/features/reservations/data/reservations_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';
import 'helpers/venue_fakes.dart';

/// A phone whose notifications the test controls.
class FakePushService implements PushService {
  FakePushService({this.tokenValue = 'phone-token-1'});

  String? tokenValue;
  int tokenAsks = 0;
  final refreshes = StreamController<String>.broadcast();
  final arrivalsController = StreamController<PushEvent>.broadcast();
  final tapsController = StreamController<PushEvent>.broadcast();

  @override
  Future<String?> token() async {
    tokenAsks++;

    return tokenValue;
  }

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  @override
  Stream<PushEvent> get arrivals => arrivalsController.stream;

  @override
  Stream<PushEvent> get taps => tapsController.stream;
}

class _FakeReservationsRepository extends ReservationsRepository {
  _FakeReservationsRepository() : super(ApiClient());

  final List<(String, String, String)> devices = [];

  @override
  Future<void> registerDevice(String code, String token, String language) async => devices.add((code, token, language));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(AppHarness, FakeVenueRepository, FakePushService)> open(
    WidgetTester tester, {
    FakePushService? push,
    VenueMeChoice me = VenueMeChoice.approved,
  }) async {
    final venue = FakeVenueRepository(me: me == VenueMeChoice.approved ? approvedStaff() : pendingStaff());
    final service = push ?? FakePushService();
    final app = AppHarness(session: testSession(roles: ['Staff']), venueRepository: venue, pushService: service);
    await app.pump(tester);

    return (app, venue, service);
  }

  group('the restaurant side', () {
    testWidgets('an approved person\'s phone is registered, in the app\'s language', (tester) async {
      final (_, venue, _) = await open(tester);

      expect(venue.registeredDevices, [('phone-token-1', 'en')]);
    });

    testWidgets('someone still waiting for approval is not registered', (tester) async {
      final (_, venue, push) = await open(tester, me: VenueMeChoice.pending);

      expect(venue.registeredDevices, isEmpty);
      expect(push.tokenAsks, 0);
    });

    testWidgets('without permission (no token) nothing is sent and the screens still work', (tester) async {
      final (_, venue, _) = await open(tester, push: FakePushService(tokenValue: null));

      expect(venue.registeredDevices, isEmpty);
      expect(find.text('Cafe One'), findsOneWidget);
    });

    testWidgets('a new token from Firebase is passed on to the server', (tester) async {
      final (_, venue, push) = await open(tester);

      push.refreshes.add('phone-token-2');
      await tester.pumpAndSettle();

      expect(venue.registeredDevices.last, ('phone-token-2', 'en'));
    });

    testWidgets('changing the language tells the server, so notifications follow it', (tester) async {
      final (app, venue, _) = await open(tester);

      await app.container.read(localeProvider.notifier).select('ru');
      await tester.pumpAndSettle();

      expect(venue.registeredDevices.last, ('phone-token-1', 'ru'));
    });

    testWidgets('signing out stops the notifications first, while still signed in', (tester) async {
      final (app, venue, _) = await open(tester);
      int? signOutsSeenAtUnregister;
      venue.onUnregister = () => signOutsSeenAtUnregister = app.auth.logoutCalls.length;

      await tester.tap(find.byKey(const Key('signOut')));
      await tester.pumpAndSettle();

      expect(venue.unregisteredDevices, ['phone-token-1']);
      expect(signOutsSeenAtUnregister, 0, reason: 'the server must still know who is asking');
      expect(app.auth.logoutCalls, hasLength(1));
    });
  });

  group('notifications arriving', () {
    testWidgets('a new-request notification brings the request in at once', (tester) async {
      final (_, venue, push) = await open(tester);
      expect(find.byKey(const Key('noRequests')), findsOneWidget);

      venue.reservations['NEW111'] = reservationOf('NEW111', status: ReservationState.pending);
      push.arrivalsController.add(const PushEvent(type: 'newRequest', code: 'NEW111'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('request-NEW111')), findsOneWidget);
    });

    testWidgets('tapping a new-request notification opens the restaurant screens', (tester) async {
      final (app, _, push) = await open(tester);
      app.router.go('/');
      await tester.pumpAndSettle();
      expect(app.currentPath, '/');

      push.tapsController.add(const PushEvent(type: 'newRequest', code: 'NEW111'));
      await tester.pumpAndSettle();

      expect(app.currentPath, '/venue');
    });
  });

  group('the customer side', () {
    test('a sent request registers this phone for the answer, with its code and the language', () async {
      final repository = _FakeReservationsRepository();
      final container = ProviderContainer(overrides: [
        pushServiceProvider.overrideWithValue(FakePushService(tokenValue: 'customer-token')),
        reservationsRepositoryProvider.overrideWithValue(repository),
        localeProvider.overrideWith((ref) => LocaleController(const Locale('ru'))),
      ]);
      addTearDown(container.dispose);

      await container.read(pushRegistrarProvider).registerReservation('AB12CD');

      expect(repository.devices, [('AB12CD', 'customer-token', 'ru')]);
    });

    test('without a token nothing is sent', () async {
      final repository = _FakeReservationsRepository();
      final container = ProviderContainer(overrides: [
        pushServiceProvider.overrideWithValue(FakePushService(tokenValue: null)),
        reservationsRepositoryProvider.overrideWithValue(repository),
      ]);
      addTearDown(container.dispose);

      await container.read(pushRegistrarProvider).registerReservation('AB12CD');

      expect(repository.devices, isEmpty);
    });
  });
}

enum VenueMeChoice { approved, pending }
