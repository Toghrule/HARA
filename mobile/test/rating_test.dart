import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/reservations/data/reservation_state.dart';
import 'package:hara/features/reservations/data/reservations_repository.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:hara/features/restaurants/presentation/screens/restaurant_detail_screen.dart';
import 'package:hara/l10n/app_localizations.dart';

class _Capture implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Map<String, dynamic> answer = const {};

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);

    return ResponseBody.fromString(
      options.method == 'GET' ? '{"code":"ABC123","status":${answer['status'] ?? 1},"expiresAt":"2030-01-01T00:00:00Z","redeemedAt":null,"rating":${answer['rating']}}' : '',
      options.method == 'GET' ? 200 : 204,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeRestaurantsRepository extends RestaurantsRepository {
  _FakeRestaurantsRepository(this._restaurant) : super(ApiClient());

  final Restaurant _restaurant;

  @override
  Future<Restaurant> getRestaurant(String id) async => _restaurant;
}

Restaurant _restaurantFrom(Map<String, dynamic> extra) => Restaurant.fromJson({
      'id': 'rest1',
      'name': 'Mixek Restoran',
      'address': 'Baku',
      'latitude': 40.4,
      'longitude': 49.8,
      ...extra,
    });

void main() {
  group('what the server tells and is told', () {
    test('a restaurant carries its average and how many rated', () {
      final rated = _restaurantFrom({'ratingAverage': 4.5, 'ratingCount': 12});

      expect(rated.ratingAverage, 4.5);
      expect(rated.ratingCount, 12);
    });

    test('a restaurant nobody rated has no average', () {
      final unrated = _restaurantFrom({'ratingAverage': null, 'ratingCount': 0});

      expect(unrated.ratingAverage, isNull);
      expect(unrated.ratingCount, 0);
      expect(_restaurantFrom({}).ratingAverage, isNull);
    });

    test('whole-number averages from the server are read as numbers', () {
      expect(_restaurantFrom({'ratingAverage': 4, 'ratingCount': 1}).ratingAverage, 4.0);
    });

    test('rating sends the stars to the reservation\'s own address', () async {
      final adapter = _Capture();
      final repository = ReservationsRepository(ApiClient()..dio.httpClientAdapter = adapter);

      await repository.rate('ABC123', 5);

      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/api/reservations/ABC123/rating');
      expect(adapter.requests.single.data, {'stars': 5});
    });

    test('the status says how many stars this phone already gave', () async {
      final adapter = _Capture()..answer = {'status': 1, 'rating': 4};
      final repository = ReservationsRepository(ApiClient()..dio.httpClientAdapter = adapter);

      final info = await repository.getStatus('ABC123');

      expect(info!.state, ReservationState.redeemed);
      expect(info.rating, 4);
    });

    test('no stars given yet is null', () async {
      final adapter = _Capture()..answer = {'status': 1, 'rating': null};
      final repository = ReservationsRepository(ApiClient()..dio.httpClientAdapter = adapter);

      expect((await repository.getStatus('ABC123'))!.rating, isNull);
    });
  });

  group('on the restaurant page', () {
    Future<void> pump(WidgetTester tester, Restaurant restaurant) {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      return tester.pumpWidget(
        ProviderScope(
          overrides: [restaurantsRepositoryProvider.overrideWithValue(_FakeRestaurantsRepository(restaurant))],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const RestaurantDetailScreen(restaurantId: 'rest1'),
          ),
        ),
      );
    }

    testWidgets('shows the average with how many rated', (tester) async {
      await pump(tester, _restaurantFrom({'ratingAverage': 4.5, 'ratingCount': 12}));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rating')), findsOneWidget);
      expect(find.text('★ 4.5 (12)'), findsOneWidget);
    });

    testWidgets('shows nothing while nobody has rated', (tester) async {
      await pump(tester, _restaurantFrom({}));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rating')), findsNothing);
    });
  });
}
