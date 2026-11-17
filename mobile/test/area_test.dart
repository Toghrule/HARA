import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurant_filters.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';

Restaurant _r(String id, String name, {String? district}) => Restaurant(
      id: id,
      name: name,
      address: 'Baku, $name street',
      latitude: 40.4,
      longitude: 49.8,
      district: district,
    );

class _Capture implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);

    return ResponseBody.fromString(
      options.path.endsWith('/areas') ? '[{"code":"nasimi","count":2},{"code":"sabail","count":1}]' : '[]',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('what the server is asked', () {
    test('the areas come from their own address', () async {
      final adapter = _Capture();
      final repository = RestaurantsRepository(ApiClient()..dio.httpClientAdapter = adapter);

      final areas = await repository.getAreas();

      expect(adapter.requests.single.path, '/api/restaurants/areas');
      expect(areas.map((a) => '${a.code}:${a.count}'), ['nasimi:2', 'sabail:1']);
    });

    test('the list is narrowed to an area with a question the server understands', () async {
      final adapter = _Capture();
      final repository = RestaurantsRepository(ApiClient()..dio.httpClientAdapter = adapter);

      await repository.getRestaurants(query: const RestaurantListQuery(district: 'nasimi'));

      expect(adapter.requests.single.queryParameters['district'], 'nasimi');
    });

    test('no area, no such question', () async {
      final adapter = _Capture();
      final repository = RestaurantsRepository(ApiClient()..dio.httpClientAdapter = adapter);

      await repository.getRestaurants();

      expect(adapter.requests.single.queryParameters.containsKey('district'), isFalse);
    });

    test('a restaurant carries its area', () {
      final restaurant = Restaurant.fromJson({'id': 'a', 'name': 'A', 'address': 'x', 'latitude': 1, 'longitude': 1, 'district': 'nasimi'});

      expect(restaurant.district, 'nasimi');
      expect(Restaurant.fromJson({'id': 'a', 'name': 'A', 'address': 'x', 'latitude': 1, 'longitude': 1}).district, isNull);
    });

    test('every area the server knows has a name in the list here', () {
      expect(districtCodes, hasLength(12));
    });
  });

  group('on the home screen', () {
    final all = [_r('a', 'Alpha', district: 'nasimi'), _r('b', 'Bravo', district: 'nasimi'), _r('c', 'Charlie', district: 'sabail'), _r('d', 'Delta')];

    Future<AppHarness> open(WidgetTester tester, List<Restaurant> restaurants) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(continuedAsCustomer: true, restaurants: restaurants);
      await app.pump(tester);

      return app;
    }

    testWidgets('"Area" lists the areas that have restaurants, the busiest first', (tester) async {
      await open(tester, all);

      expect(find.byKey(const Key('areaSection')), findsOneWidget);
      expect(find.text('Area'), findsOneWidget);
      expect(find.byKey(const Key('area-nasimi')), findsOneWidget);
      expect(find.byKey(const Key('area-sabail')), findsOneWidget);
      expect(find.byKey(const Key('area-yasamal')), findsNothing, reason: 'nobody is there');
      expect(tester.getTopLeft(find.byKey(const Key('area-nasimi'))).dx, lessThan(tester.getTopLeft(find.byKey(const Key('area-sabail'))).dx));
      expect(find.text('Nasimi'), findsOneWidget);
    });

    testWidgets('no section when no restaurant has an area', (tester) async {
      await open(tester, [_r('a', 'Alpha'), _r('b', 'Bravo')]);

      expect(find.byKey(const Key('areaSection')), findsNothing);
    });

    testWidgets('picking an area shows only its restaurants, and keeps the chips so it can be unpicked', (tester) async {
      final app = await open(tester, all);

      await tester.tap(find.byKey(const Key('area-nasimi')));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Bravo'), findsOneWidget);
      expect(find.text('Charlie'), findsNothing);
      expect(find.text('Delta'), findsNothing);
      expect(app.restaurants.queries.last.query.district, 'nasimi');
      expect(tester.widget<FilterChip>(find.byKey(const Key('area-nasimi'))).selected, isTrue);
      expect(find.byKey(const Key('areaSection')), findsOneWidget);

      await tester.tap(find.byKey(const Key('area-nasimi')));
      await tester.pumpAndSettle();

      expect(app.restaurants.queries.last.query.district, isNull);
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('another area replaces the first', (tester) async {
      await open(tester, all);

      await tester.tap(find.byKey(const Key('area-nasimi')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('area-sabail')));
      await tester.pumpAndSettle();

      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
    });

    testWidgets('searching hides the area chips, like the other rows', (tester) async {
      await open(tester, all);

      await tester.enterText(find.byType(TextField), 'Alp');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('areaSection')), findsNothing);
    });
  });
}
