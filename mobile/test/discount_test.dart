import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hara/core/feature_flags.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/discounts/data/discount_code.dart';
import 'package:hara/features/discounts/data/discounts_repository.dart';
import 'package:hara/features/discounts/presentation/discount_code_screen.dart';
import 'package:hara/features/reservations/data/reservation_state.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurant_filters.dart';
import 'package:hara/features/restaurants/data/restaurant_sort.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:hara/features/restaurants/presentation/screens/restaurant_detail_screen.dart';
import 'package:hara/features/venue/data/venue_repository.dart';
import 'package:hara/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Capture implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (status >= 400) {
      return ResponseBody.fromString('{}', status, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }

    return ResponseBody.fromString(
      '{"code":"K7M2QD","restaurantId":"rest1","restaurantName":"Kinder","discountPercent":15,"createdAt":"2030-01-01T00:00:00Z","expiresAt":"2030-01-01T06:00:00Z","status":0,"redeemedAt":null,"id":"x","phoneNumber":"","durationMinutes":360}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DiscountCode _code({ReservationState status = ReservationState.active, Duration left = const Duration(hours: 5, minutes: 59, seconds: 30)}) => DiscountCode(
      code: 'K7M2QD',
      restaurantId: 'rest1',
      restaurantName: 'Kinder',
      discountPercent: 15,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(left),
      status: status,
    );

class _FakeDiscounts extends DiscountsRepository {
  _FakeDiscounts() : super(ApiClient(), () async => 'device-test-0001');

  final List<String> asked = [];
  final List<(String, String)> events = [];
  DiscountCode next = _code();
  DiscountCode? statusAnswer;
  Object? error;

  @override
  Future<DiscountCode> getCode(String restaurantId) async {
    asked.add(restaurantId);
    if (error != null) throw error!;

    return next;
  }

  @override
  Future<DiscountCode> getStatus(String code) async => statusAnswer ?? next;

  @override
  Future<void> recordEvent(String restaurantId, String type) async => events.add((restaurantId, type));
}

class _FakeRestaurants extends RestaurantsRepository {
  _FakeRestaurants(this.restaurant) : super(ApiClient());

  final Restaurant restaurant;

  @override
  Future<Restaurant> getRestaurant(String id) async => restaurant;

  @override
  Future<List<Restaurant>> getRestaurants({
    RestaurantSort sort = RestaurantSort.nameAsc,
    String search = '',
    int page = 1,
    int pageSize = 20,
    RestaurantListQuery query = const RestaurantListQuery(),
  }) async =>
      [restaurant];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => FeatureFlags.reservationsEnabled = false);

  group('what the server is told and answers', () {
    test('getting a code sends the anonymous number of this phone and reads the answer', () async {
      final adapter = _Capture();
      final repository = DiscountsRepository(ApiClient()..dio.httpClientAdapter = adapter, () async => 'device-test-0001');

      final code = await repository.getCode('rest1');

      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/api/restaurants/rest1/discount-code');
      expect(adapter.requests.single.data, {'deviceId': 'device-test-0001'});
      expect(code.code, 'K7M2QD');
      expect(code.discountPercent, 15);
      expect(code.status, ReservationState.active);
    });

    test('the status of a code is read from its own address', () async {
      final adapter = _Capture();
      final repository = DiscountsRepository(ApiClient()..dio.httpClientAdapter = adapter, () async => 'device-test-0001');

      await repository.getStatus('K7M2QD');

      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.path, '/api/discount-codes/K7M2QD');
    });

    test('counting a tap sends the kind and the anonymous number', () async {
      final adapter = _Capture();
      final repository = DiscountsRepository(ApiClient()..dio.httpClientAdapter = adapter, () async => 'device-test-0001');

      await repository.recordEvent('rest1', RestaurantEvent.directions);

      expect(adapter.requests.single.path, '/api/restaurants/rest1/events');
      expect(adapter.requests.single.data, {'type': 'directions', 'deviceId': 'device-test-0001'});
    });

    test('a failure to count is never an error for the customer', () async {
      final adapter = _Capture()..status = 500;
      final repository = DiscountsRepository(ApiClient()..dio.httpClientAdapter = adapter, () async => 'device-test-0001');

      await repository.recordEvent('rest1', RestaurantEvent.view);
    });

    test('the anonymous number is made once, long enough, and kept', () async {
      final first = await loadDeviceId();
      final second = await loadDeviceId();

      expect(first, second);
      expect(RegExp(r'^[A-Za-z0-9-]{8,64}$').hasMatch(first), isTrue);
    });
  });

  group('the restaurant side checks the right kind of code', () {
    Future<List<String>> pathsOf(Future<void> Function(VenueRepository) act) async {
      final adapter = _Capture();
      final repository = VenueRepository(ApiClient()..dio.httpClientAdapter = adapter);
      await act(repository);

      return adapter.requests.map((request) => request.path).toList();
    }

    test('discount codes while reservations are off', () async {
      expect(await pathsOf((repository) async => repository.lookup('K7M2QD')), ['/api/venue/discount-codes/K7M2QD']);
      expect(await pathsOf((repository) async => repository.redeem('K7M2QD')), ['/api/venue/discount-codes/K7M2QD/redeem']);
    });

    test('reservation codes when reservations are switched on', () async {
      FeatureFlags.reservationsEnabled = true;

      expect(await pathsOf((repository) async => repository.lookup('K7M2QD')), ['/api/venue/reservations/K7M2QD']);
    });
  });

  group('the restaurant page', () {
    Future<_FakeDiscounts> open(WidgetTester tester, Restaurant restaurant, {void Function(_FakeDiscounts)? configure}) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final discounts = _FakeDiscounts();
      configure?.call(discounts);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => const RestaurantDetailScreen(restaurantId: 'rest1')),
          GoRoute(path: '/discount', builder: (context, state) => DiscountCodeScreen(code: state.extra! as DiscountCode)),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            restaurantsRepositoryProvider.overrideWithValue(_FakeRestaurants(restaurant)),
            discountsRepositoryProvider.overrideWithValue(discounts),
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

      return discounts;
    }

    const withDiscount = Restaurant(id: 'rest1', name: 'Kinder', address: 'Baku', latitude: 40.4, longitude: 49.8, discountPercent: 15);
    const without = Restaurant(id: 'rest1', name: 'Plain Cafe', address: 'Baku', latitude: 40.4, longitude: 49.8);

    testWidgets('a restaurant that gives a discount offers "Get the discount"', (tester) async {
      await open(tester, withDiscount);

      expect(find.byKey(const Key('getDiscount')), findsOneWidget);
      expect(find.text('Get the discount'), findsOneWidget);
    });

    testWidgets('a restaurant with no discount offers no button', (tester) async {
      await open(tester, without);

      expect(find.byKey(const Key('getDiscount')), findsNothing);
    });

    testWidgets('opening the page is counted once', (tester) async {
      final discounts = await open(tester, withDiscount);

      expect(discounts.events, [('rest1', 'view')]);
    });

    testWidgets('tapping the button asks for the code and shows the ticket', (tester) async {
      final discounts = await open(tester, withDiscount);

      await tester.tap(find.byKey(const Key('getDiscount')));
      await tester.pumpAndSettle();

      expect(discounts.asked, ['rest1']);
      expect(find.byKey(const Key('discountCode')), findsOneWidget);
      expect(find.text('K7M2QD'), findsOneWidget);
      expect(find.textContaining('Valid for 5:59:'), findsOneWidget);
      expect(find.text('One code per restaurant per day.'), findsOneWidget);
    });

    testWidgets('a server that cannot be reached says so and stays on the page', (tester) async {
      final discounts = await open(
        tester,
        withDiscount,
        configure: (discounts) => discounts.error = DioException(requestOptions: RequestOptions(path: '/x'), type: DioExceptionType.connectionError),
      );

      await tester.tap(find.byKey(const Key('getDiscount')));
      await tester.pump();
      await tester.pump();

      expect(discounts.asked, ['rest1']);
      expect(find.byKey(const Key('discountCode')), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('the ticket', () {
    Future<void> show(WidgetTester tester, DiscountCode code, {DiscountCode? statusAnswer}) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final discounts = _FakeDiscounts()
        ..next = code
        ..statusAnswer = statusAnswer;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [discountsRepositoryProvider.overrideWithValue(discounts)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: DiscountCodeScreen(code: code),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('a valid code counts its six hours down and says what to do', (tester) async {
      await show(tester, _code());

      expect(find.textContaining('Valid for 5:59:'), findsOneWidget);
      expect(find.textContaining('15%'), findsWidgets);
      expect(find.byKey(const Key('discountDone')), findsOneWidget);
    });

    testWidgets('a code the restaurant confirmed says so', (tester) async {
      await show(tester, _code(status: ReservationState.redeemed));

      expect(find.text('Discount confirmed'), findsOneWidget);
      expect(find.textContaining('Valid for'), findsNothing);
    });

    testWidgets('a code that ran out says so and that a new one comes tomorrow', (tester) async {
      await show(tester, _code(status: ReservationState.expired, left: Duration.zero));

      expect(find.text('This code has expired'), findsOneWidget);
      expect(find.textContaining('tomorrow'), findsOneWidget);
    });

    testWidgets('the ticket follows the restaurant: confirmed while it is open', (tester) async {
      await show(tester, _code(), statusAnswer: _code(status: ReservationState.redeemed));
      expect(find.textContaining('Valid for'), findsOneWidget);

      await tester.pump(const Duration(seconds: 21));
      await tester.pump();

      expect(find.text('Discount confirmed'), findsOneWidget);
    });
  });
}
