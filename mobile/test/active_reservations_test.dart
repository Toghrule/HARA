import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/reservations/data/reservation.dart';
import 'package:hara/features/reservations/data/reservation_state.dart';
import 'package:hara/features/reservations/data/reservations_repository.dart';
import 'package:hara/features/reservations/presentation/providers/active_reservations_provider.dart';
import 'package:hara/features/reservations/presentation/screens/reservation_code_screen.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurant_sort.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:hara/features/restaurants/presentation/screens/restaurants_screen.dart';
import 'package:hara/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _restaurant = Restaurant(
  id: 'rest1',
  name: 'Test Restoran',
  address: 'Test st 1',
  latitude: 40.4,
  longitude: 49.8,
  discountPercent: 15,
);

Reservation _reservation({required Duration expiresIn, String code = 'S68NRG'}) => Reservation(
      id: 'r-$code',
      restaurantId: 'rest1',
      restaurantName: 'Test Restoran',
      discountPercent: 15,
      code: code,
      durationMinutes: 30,
      expiresAt: DateTime.now().add(expiresIn),
    );

void _store(List<Reservation> reservations) => SharedPreferences.setMockInitialValues({
      'active_reservations': jsonEncode(reservations.map((reservation) => reservation.toJson()).toList()),
    });

Future<List<Reservation>> _loaded(ProviderContainer container) async {
  container.read(activeReservationsProvider);
  await container.read(activeReservationsProvider.notifier).add(_reservation(expiresIn: Duration.zero, code: 'WAIT00'));
  await container.read(activeReservationsProvider.notifier).remove('WAIT00');

  return container.read(activeReservationsProvider);
}

class _FakeRestaurantsRepository extends RestaurantsRepository {
  _FakeRestaurantsRepository() : super(ApiClient());

  @override
  Future<List<Restaurant>> getRestaurants({
    RestaurantSort sort = RestaurantSort.nameAsc,
    String search = '',
    int page = 1,
    int pageSize = 20,
  }) async =>
      const [_restaurant];
}

class _FakeReservationsRepository extends ReservationsRepository {
  _FakeReservationsRepository() : super(ApiClient());

  final List<String> cancelled = [];

  /// What the server says per code; a code that is absent counts as still active, a `null` value as unknown (404).
  final Map<String, ReservationState?> statuses = {};
  Object? statusError;
  int statusChecks = 0;

  @override
  Future<ReservationState?> getStatus(String code) async {
    statusChecks++;
    if (statusError != null) throw statusError!;

    return statuses.containsKey(code) ? statuses[code] : ReservationState.active;
  }

  @override
  Future<Reservation> create({
    required String restaurantId,
    required String phoneNumber,
    required int durationMinutes,
  }) async =>
      _reservation(expiresIn: Duration(minutes: durationMinutes), code: 'NEW123');

  @override
  Future<void> cancel(String code) async => cancelled.add(code);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ActiveReservations', () {
    test('keeps a new reservation on the device and finds it again later', () async {
      final first = ProviderContainer();
      addTearDown(first.dispose);
      await first.read(activeReservationsProvider.notifier).add(_reservation(expiresIn: const Duration(minutes: 30)));

      final second = ProviderContainer();
      addTearDown(second.dispose);

      expect((await _loaded(second)).map((reservation) => reservation.code), ['S68NRG']);
    });

    test('forgets reservations whose time is up when the app starts', () async {
      _store([
        _reservation(expiresIn: const Duration(minutes: -1), code: 'OLD111'),
        _reservation(expiresIn: const Duration(minutes: 10), code: 'LIVE22'),
      ]);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect((await _loaded(container)).map((reservation) => reservation.code), ['LIVE22']);
    });

    test('remove forgets a reservation for good', () async {
      final first = ProviderContainer();
      addTearDown(first.dispose);
      final notifier = first.read(activeReservationsProvider.notifier);
      await notifier.add(_reservation(expiresIn: const Duration(minutes: 30)));
      await notifier.remove('S68NRG');

      expect(first.read(activeReservationsProvider), isEmpty);

      final second = ProviderContainer();
      addTearDown(second.dispose);
      expect(await _loaded(second), isEmpty);
    });

    test('booking the same code twice keeps one copy', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(activeReservationsProvider.notifier);
      await notifier.add(_reservation(expiresIn: const Duration(minutes: 30)));
      await notifier.add(_reservation(expiresIn: const Duration(minutes: 30)));

      expect(container.read(activeReservationsProvider), hasLength(1));
    });

    test('unreadable saved data is ignored instead of breaking the app', () async {
      SharedPreferences.setMockInitialValues({'active_reservations': 'not json'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await _loaded(container), isEmpty);
    });
  });

  group('on the restaurant list', () {
    late _FakeReservationsRepository reservations;

    Future<ProviderContainer> pumpApp(WidgetTester tester, {void Function(_FakeReservationsRepository)? configure}) async {
      reservations = _FakeReservationsRepository();
      configure?.call(reservations);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => const RestaurantsScreen()),
          GoRoute(
            path: '/reservation',
            builder: (context, state) => ReservationCodeScreen(reservation: state.extra! as Reservation),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            restaurantsRepositoryProvider.overrideWithValue(_FakeRestaurantsRepository()),
            reservationsRepositoryProvider.overrideWithValue(reservations),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return ProviderScope.containerOf(tester.element(find.byType(RestaurantsScreen)));
    }

    testWidgets('a running reservation shows as a card that reopens its code', (tester) async {
      _store([_reservation(expiresIn: const Duration(minutes: 29, seconds: 30))]);
      await pumpApp(tester);

      expect(find.text('Your reservation: Test Restoran'), findsOneWidget);
      expect(find.textContaining('Code S68NRG · 29:'), findsOneWidget);

      await tester.tap(find.text('Your reservation: Test Restoran'));
      await tester.pumpAndSettle();

      expect(find.text('S68NRG'), findsOneWidget);
      expect(find.text('Your code'), findsOneWidget);
    });

    testWidgets('no card when there is no reservation', (tester) async {
      await pumpApp(tester);

      expect(find.textContaining('Your reservation'), findsNothing);
    });

    testWidgets('a card the server says was used is dropped as soon as the list opens', (tester) async {
      _store([
        _reservation(expiresIn: const Duration(minutes: 20), code: 'USED11'),
        _reservation(expiresIn: const Duration(minutes: 20), code: 'LIVE44'),
      ]);
      await pumpApp(tester, configure: (repository) => repository.statuses['USED11'] = ReservationState.redeemed);

      expect(find.textContaining('Code USED11'), findsNothing);
      expect(find.textContaining('Code LIVE44'), findsOneWidget);
    });

    testWidgets('the list keeps checking while it stays open', (tester) async {
      _store([_reservation(expiresIn: const Duration(minutes: 20))]);
      await pumpApp(tester);
      expect(reservations.statusChecks, 1);

      reservations.statuses['S68NRG'] = ReservationState.redeemed;
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();

      expect(reservations.statusChecks, 2);
      expect(find.textContaining('Code S68NRG'), findsNothing);
    });

    testWidgets('an open code screen says when the venue has used the code', (tester) async {
      _store([_reservation(expiresIn: const Duration(minutes: 20))]);
      final container = await pumpApp(tester);

      await tester.tap(find.text('Your reservation: Test Restoran'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Valid for'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancel reservation'), findsOneWidget);

      reservations.statuses['S68NRG'] = ReservationState.redeemed;
      await container.read(activeReservationsProvider.notifier).refresh();
      await tester.pumpAndSettle();

      expect(find.text('This reservation is no longer active'), findsOneWidget);
      expect(find.textContaining('Valid for'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Cancel reservation'), findsNothing);
    });

    testWidgets('the card disappears by itself when the time is up', (tester) async {
      _store([_reservation(expiresIn: const Duration(seconds: 1))]);
      await pumpApp(tester);
      expect(find.textContaining('Code S68NRG'), findsOneWidget);

      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1300)));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.textContaining('Code S68NRG'), findsNothing);
    });

    testWidgets('reserving keeps the reservation, and cancelling it removes the card', (tester) async {
      final container = await pumpApp(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Reserve'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '+994 50 123 45 67');
      await tester.tap(find.widgetWithText(FilledButton, 'Reserve').last);
      await tester.pumpAndSettle();

      expect(find.text('NEW123'), findsOneWidget);
      expect(container.read(activeReservationsProvider).map((reservation) => reservation.code), ['NEW123']);

      // Leaving the code screen keeps the reservation available on the list.
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Code NEW123'), findsOneWidget);

      await tester.tap(find.text('Your reservation: Test Restoran'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel reservation'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel reservation'));
      await tester.pumpAndSettle();

      expect(reservations.cancelled, ['NEW123']);
      expect(container.read(activeReservationsProvider), isEmpty);
      expect(find.textContaining('Code NEW123'), findsNothing);
    });
  });
  group('checking with the server', () {
    DioException serverTrouble(int status) {
      final options = RequestOptions(path: '/status');

      return DioException(requestOptions: options, response: Response(requestOptions: options, statusCode: status));
    }

    Future<(ProviderContainer, _FakeReservationsRepository)> containerWith(List<Reservation> kept) async {
      _store(kept);
      final repository = _FakeReservationsRepository();
      final container = ProviderContainer(overrides: [reservationsRepositoryProvider.overrideWithValue(repository)]);
      addTearDown(container.dispose);
      await _loaded(container);

      return (container, repository);
    }

    List<String> codes(ProviderContainer container) =>
        container.read(activeReservationsProvider).map((reservation) => reservation.code).toList();

    test('forgets a reservation the venue used, one that was cancelled, and one the server no longer knows', () async {
      final (container, repository) = await containerWith([
        _reservation(expiresIn: const Duration(minutes: 20), code: 'USED11'),
        _reservation(expiresIn: const Duration(minutes: 20), code: 'CANC22'),
        _reservation(expiresIn: const Duration(minutes: 20), code: 'GONE33'),
        _reservation(expiresIn: const Duration(minutes: 20), code: 'LIVE44'),
      ]);
      repository.statuses
        ..['USED11'] = ReservationState.redeemed
        ..['CANC22'] = ReservationState.cancelled
        ..['GONE33'] = null;

      await container.read(activeReservationsProvider.notifier).refresh();

      expect(codes(container), ['LIVE44']);
    });

    test('keeps every reservation when the server cannot be reached or is in trouble', () async {
      final (container, repository) = await containerWith([
        _reservation(expiresIn: const Duration(minutes: 20), code: 'KEEP11'),
      ]);

      repository.statusError = serverTrouble(500);
      await container.read(activeReservationsProvider.notifier).refresh();
      repository.statusError = DioException(requestOptions: RequestOptions(path: '/status'));
      await container.read(activeReservationsProvider.notifier).refresh();
      repository.statusError = serverTrouble(429);
      await container.read(activeReservationsProvider.notifier).refresh();

      expect(codes(container), ['KEEP11']);
      expect(repository.statusChecks, 3);
    });

    test('a reservation forgotten after a check stays forgotten on the next start', () async {
      final (container, repository) = await containerWith([
        _reservation(expiresIn: const Duration(minutes: 20), code: 'USED11'),
      ]);
      repository.statuses['USED11'] = ReservationState.redeemed;
      await container.read(activeReservationsProvider.notifier).refresh();

      final next = ProviderContainer();
      addTearDown(next.dispose);

      expect(await _loaded(next), isEmpty);
    });
  });

}
