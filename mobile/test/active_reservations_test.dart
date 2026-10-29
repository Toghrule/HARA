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
import 'package:hara/features/restaurants/data/restaurant_filters.dart';
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

Reservation _reservation({
  required Duration expiresIn,
  String code = 'S68NRG',
  ReservationState status = ReservationState.active,
}) =>
    Reservation(
      status: status,
      id: 'r-$code',
      restaurantId: 'rest1',
      restaurantName: 'Test Restoran',
      discountPercent: 15,
      code: code,
      durationMinutes: 30,
      expiresAt: DateTime.now().add(expiresIn),
    );

/// The deadlines of what was put on the phone, so a fake server can report them back unchanged.
final Map<String, DateTime> _storedDeadlines = {};

/// Likewise the states, so a reservation put on the phone as pending is reported as pending until a test says otherwise.
final Map<String, ReservationState> _storedStates = {};

void _store(List<Reservation> reservations) {
  _storedDeadlines
    ..clear()
    ..addEntries(reservations.map((reservation) => MapEntry(reservation.code, reservation.expiresAt)));
  _storedStates
    ..clear()
    ..addEntries(reservations.map((reservation) => MapEntry(reservation.code, reservation.status)));
  SharedPreferences.setMockInitialValues({
    'active_reservations': jsonEncode(reservations.map((reservation) => reservation.toJson()).toList()),
  });
}

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
    RestaurantListQuery query = const RestaurantListQuery(),
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

  /// The deadline the server reports per code (defaults to 20 minutes from now).
  final Map<String, DateTime> deadlines = {};

  @override
  Future<ReservationStatusInfo?> getStatus(String code) async {
    statusChecks++;
    if (statusError != null) throw statusError!;

    final state = statuses.containsKey(code) ? statuses[code] : (_storedStates[code] ?? ReservationState.active);
    if (state == null) return null;

    return ReservationStatusInfo(state: state, expiresAt: deadlines[code] ?? _storedDeadlines[code] ?? DateTime.now().add(const Duration(minutes: 20)));
  }

  @override
  Future<Reservation> create({
    required String restaurantId,
    required String phoneNumber,
    required int durationMinutes,
  }) async =>
      _reservation(expiresIn: const Duration(minutes: 15), code: 'NEW123', status: ReservationState.pending);

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

    testWidgets('sending a request shows the waiting screen, and no code until the restaurant accepts', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = await pumpApp(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Reserve'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '+994 50 123 45 67');
      await tester.tap(find.widgetWithText(FilledButton, 'Send request'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('waitingTitle')), findsOneWidget);
      expect(find.textContaining('The restaurant has 14:5'), findsOneWidget, reason: 'it has 15 minutes to answer');
      expect(find.text('NEW123'), findsNothing, reason: 'the code is shown only after the restaurant accepts');
      expect(container.read(activeReservationsProvider).single.status, ReservationState.pending);

      // Leaving the screen keeps the request on the list.
      await tester.tap(find.byKey(const Key('done')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Waiting for the restaurant · 14:'), findsOneWidget);
    });

    testWidgets('when the restaurant accepts, the open screen turns into the code with a fresh 30 minutes', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      _store([_reservation(expiresIn: const Duration(minutes: 9), status: ReservationState.pending)]);
      final container = await pumpApp(tester);

      await tester.tap(find.byKey(const Key('reservationCard-S68NRG')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('waitingTitle')), findsOneWidget);
      expect(find.text('S68NRG'), findsNothing);

      // The restaurant accepts: the server now reports Active with a deadline 30 minutes from the moment it did.
      reservations.statuses['S68NRG'] = ReservationState.active;
      reservations.deadlines['S68NRG'] = DateTime.now().add(const Duration(minutes: 30));
      await container.read(activeReservationsProvider.notifier).refresh();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('waitingTitle')), findsNothing);
      expect(find.text('S68NRG'), findsOneWidget);
      expect(find.byKey(const Key('confirmedByRestaurant')), findsOneWidget);
      expect(find.textContaining('Valid for 29:5'), findsOneWidget, reason: 'the 30 minutes started when the restaurant accepted');
      expect(container.read(activeReservationsProvider).single.status, ReservationState.active);
    });

    testWidgets('the screen follows the restaurant by itself, without anyone refreshing it', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      _store([_reservation(expiresIn: const Duration(minutes: 9), status: ReservationState.pending)]);
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('reservationCard-S68NRG')));
      await tester.pumpAndSettle();
      final checksBefore = reservations.statusChecks;

      reservations.statuses['S68NRG'] = ReservationState.active;
      reservations.deadlines['S68NRG'] = DateTime.now().add(const Duration(minutes: 30));
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();

      expect(reservations.statusChecks, greaterThan(checksBefore));
      expect(find.text('S68NRG'), findsOneWidget);
    });

    testWidgets('a declined request tells the customer, and closing it clears it', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      _store([_reservation(expiresIn: const Duration(minutes: 9), status: ReservationState.pending)]);
      final container = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('reservationCard-S68NRG')));
      await tester.pumpAndSettle();

      reservations.statuses['S68NRG'] = ReservationState.declined;
      await container.read(activeReservationsProvider.notifier).refresh();
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('outcomeTitle'))).data, 'The restaurant declined your request');
      expect(find.text('S68NRG'), findsNothing);

      await tester.tap(find.byKey(const Key('done')));
      await tester.pumpAndSettle();
      expect(container.read(activeReservationsProvider), isEmpty);
      expect(find.byKey(const Key('reservationCard-S68NRG')), findsNothing);
    });

    testWidgets('a decline that nobody opened stays on the list as a notice until it is closed', (tester) async {
      _store([_reservation(expiresIn: const Duration(minutes: 9), status: ReservationState.pending)]);
      final container = await pumpApp(tester);

      reservations.statuses['S68NRG'] = ReservationState.declined;
      await container.read(activeReservationsProvider.notifier).refresh();
      await tester.pumpAndSettle();

      expect(find.text('Test Restoran declined your request'), findsOneWidget);

      await tester.tap(find.byKey(const Key('closeNotice-S68NRG')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reservationCard-S68NRG')), findsNothing);
    });

    testWidgets('a request nobody answers in time becomes a "no answer" notice', (tester) async {
      _store([_reservation(expiresIn: const Duration(seconds: 1), status: ReservationState.pending)]);
      await pumpApp(tester);
      expect(find.textContaining('Waiting for the restaurant'), findsOneWidget);

      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1300)));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Test Restoran did not answer'), findsOneWidget);
    });

    testWidgets('the customer can cancel a request while it waits', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      _store([_reservation(expiresIn: const Duration(minutes: 9), status: ReservationState.pending)]);
      final container = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('reservationCard-S68NRG')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelRequest')));
      await tester.pumpAndSettle();
      expect(find.text('Cancel your request?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancelDialogYes')));
      await tester.pumpAndSettle();

      expect(reservations.cancelled, ['S68NRG']);
      expect(container.read(activeReservationsProvider), isEmpty);
      expect(find.text('Request cancelled'), findsOneWidget);
    });

    testWidgets('an accepted reservation can still be cancelled, and leaves the list', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      _store([_reservation(expiresIn: const Duration(minutes: 25))]);
      final container = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('reservationCard-S68NRG')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelReservation')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancelDialogYes')));
      await tester.pumpAndSettle();

      expect(reservations.cancelled, ['S68NRG']);
      expect(container.read(activeReservationsProvider), isEmpty);
      expect(find.textContaining('Code S68NRG'), findsNothing);
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

  group('requests and the restaurant\'s answer', () {
    Future<(ProviderContainer, _FakeReservationsRepository)> containerWith(List<Reservation> kept) async {
      _store(kept);
      final repository = _FakeReservationsRepository();
      final container = ProviderContainer(overrides: [reservationsRepositoryProvider.overrideWithValue(repository)]);
      addTearDown(container.dispose);
      await _loaded(container);

      return (container, repository);
    }

    Reservation only(ProviderContainer container) => container.read(activeReservationsProvider).single;

    test('a reservation saved before restaurants had to accept is read as accepted', () {
      final reservation = Reservation.fromJson({
        'id': 'x',
        'restaurantId': 'r',
        'restaurantName': 'Old',
        'discountPercent': 10,
        'code': 'OLD123',
        'durationMinutes': 30,
        'expiresAt': '2026-10-06T09:31:29.1872135+00:00',
      });

      expect(reservation.status, ReservationState.active);
    });

    test('the state and deadline survive being put on the device', () {
      final original = _reservation(expiresIn: const Duration(minutes: 9), status: ReservationState.pending);
      final copy = Reservation.fromJson(original.toJson());

      expect(copy.status, ReservationState.pending);
      expect(copy.expiresAt.difference(original.expiresAt).inSeconds.abs(), lessThan(1));
    });

    test('when the restaurant accepts, the saved copy gets the new state and the new deadline', () async {
      final (container, repository) = await containerWith([_reservation(expiresIn: const Duration(minutes: 9), status: ReservationState.pending)]);
      final accepted = DateTime.now().add(const Duration(minutes: 30));
      repository.statuses['S68NRG'] = ReservationState.active;
      repository.deadlines['S68NRG'] = accepted;

      await container.read(activeReservationsProvider.notifier).refresh();

      expect(only(container).status, ReservationState.active);
      expect(only(container).expiresAt, accepted);

      // ...and it is what the next start finds.
      final next = ProviderContainer();
      addTearDown(next.dispose);
      final reloaded = (await _loaded(next)).single;
      expect(reloaded.status, ReservationState.active);
      expect(reloaded.expiresAt.difference(accepted).inSeconds.abs(), lessThan(1));
    });

    test('a request still waiting is left alone', () async {
      final (container, _) = await containerWith([_reservation(expiresIn: const Duration(minutes: 9), status: ReservationState.pending)]);

      await container.read(activeReservationsProvider.notifier).refresh();

      expect(only(container).status, ReservationState.pending);
    });

    test('a declined request stays as a notice, but is not brought back after a restart', () async {
      final (container, repository) = await containerWith([_reservation(expiresIn: const Duration(minutes: 9), status: ReservationState.pending)]);
      repository.statuses['S68NRG'] = ReservationState.declined;

      await container.read(activeReservationsProvider.notifier).refresh();
      expect(only(container).status, ReservationState.declined);

      final next = ProviderContainer();
      addTearDown(next.dispose);
      expect(await _loaded(next), isEmpty);
    });

    test('a notice is not asked about again', () async {
      final (container, repository) = await containerWith([_reservation(expiresIn: const Duration(minutes: 9), status: ReservationState.pending)]);
      repository.statuses['S68NRG'] = ReservationState.declined;
      await container.read(activeReservationsProvider.notifier).refresh();
      final checks = repository.statusChecks;

      await container.read(activeReservationsProvider.notifier).refresh();

      expect(repository.statusChecks, checks);
    });

    test('a request the server says nobody answered becomes a notice too', () async {
      final (container, repository) = await containerWith([_reservation(expiresIn: const Duration(minutes: 9), status: ReservationState.pending)]);
      repository.statuses['S68NRG'] = ReservationState.unanswered;

      await container.read(activeReservationsProvider.notifier).refresh();

      expect(only(container).status, ReservationState.unanswered);
    });

    test('a request cancelled elsewhere, or an accepted one that ran out, simply goes away', () async {
      final (container, repository) = await containerWith([
        _reservation(expiresIn: const Duration(minutes: 9), status: ReservationState.pending, code: 'GONE11'),
        _reservation(expiresIn: const Duration(minutes: 9), code: 'RAN222'),
      ]);
      repository.statuses['GONE11'] = ReservationState.cancelled;
      repository.statuses['RAN222'] = ReservationState.expired;

      await container.read(activeReservationsProvider.notifier).refresh();

      expect(container.read(activeReservationsProvider), isEmpty);
    });

    test('when the deadline passes on the phone, a waiting request becomes unanswered and an accepted one ends', () async {
      final (container, _) = await containerWith([
        _reservation(expiresIn: const Duration(minutes: 9), status: ReservationState.pending, code: 'WAIT11'),
        _reservation(expiresIn: const Duration(minutes: 9), code: 'HELD22'),
      ]);
      final notifier = container.read(activeReservationsProvider.notifier);

      await notifier.deadlinePassed('WAIT11');
      await notifier.deadlinePassed('HELD22');

      final left = container.read(activeReservationsProvider);
      expect(left.map((reservation) => reservation.code), ['WAIT11']);
      expect(left.single.status, ReservationState.unanswered);
    });

    test('a request whose answer time already ran out is not kept across a restart', () async {
      _store([_reservation(expiresIn: const Duration(minutes: -1), status: ReservationState.pending)]);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await _loaded(container), isEmpty);
    });
  });

}
