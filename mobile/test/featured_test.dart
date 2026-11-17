import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';

Restaurant _r(String id, String name, {int discount = 0}) => Restaurant(
      id: id,
      name: name,
      address: 'Baku, $name street',
      latitude: 40.4,
      longitude: 49.8,
      discountPercent: discount,
      cuisines: const ['cafe'],
    );

class _Capture implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);

    return ResponseBody.fromString(
      status == 200
          ? '[{"id":"a","name":"Aaa","address":"Baku","latitude":40.4,"longitude":49.8,"discountPercent":10,"isFeatured":true,"featuredFrom":"2026-11-16","featuredUntil":"2026-11-22"}]'
          : '{}',
      status,
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

  Future<AppHarness> open(WidgetTester tester, {required List<Restaurant> all, List<Restaurant> featured = const []}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = AppHarness(continuedAsCustomer: true, restaurants: all);
    app.restaurants.featured = [...featured];
    await app.pump(tester);

    return app;
  }

  test('the picks are read from their own address', () async {
    final adapter = _Capture();
    final repository = RestaurantsRepository(ApiClient()..dio.httpClientAdapter = adapter);

    final picks = await repository.getFeatured();

    expect(adapter.requests.single.path, '/api/restaurants/featured');
    expect(picks.single.name, 'Aaa');
  });

  group('on the home screen', () {
    final all = [_r('a', 'Alpha', discount: 10), _r('b', 'Bravo', discount: 15), _r('c', 'Charlie', discount: 20), _r('d', 'Delta')];

    testWidgets('this week\'s picks are the very first thing, above the discounts', (tester) async {
      await open(tester, all: all, featured: [_r('d', 'Delta')]);

      expect(find.byKey(const Key('featuredStrip')), findsOneWidget);
      expect(find.text('This week\'s picks'), findsOneWidget);
      expect(find.byKey(const Key('featured-d')), findsOneWidget);
      expect(find.text('Pick of the week'), findsOneWidget);

      final featuredTop = tester.getTopLeft(find.byKey(const Key('featuredStrip'))).dy;
      final discountsTop = tester.getTopLeft(find.byKey(const Key('discountStrip'))).dy;
      expect(featuredTop, lessThan(discountsTop));
    });

    testWidgets('a pick shows even when no place gives a discount enough for the discounts row', (tester) async {
      await open(tester, all: [_r('a', 'Alpha'), _r('b', 'Bravo')], featured: [_r('a', 'Alpha')]);

      expect(find.byKey(const Key('featuredStrip')), findsOneWidget);
      expect(find.byKey(const Key('discountStrip')), findsNothing);
    });

    testWidgets('no row when nobody has a turn this week', (tester) async {
      await open(tester, all: all);

      expect(find.byKey(const Key('featuredStrip')), findsNothing);
    });

    testWidgets('it does not depend on the sort: the nearest order keeps the picks on top', (tester) async {
      await open(tester, all: all, featured: [_r('d', 'Delta')]);

      await tester.tap(find.byKey(const Key('sortButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('featuredStrip')), findsOneWidget);
    });

    testWidgets('searching or filtering goes straight to what was asked for', (tester) async {
      await open(tester, all: all, featured: [_r('d', 'Delta')]);

      await tester.enterText(find.byType(TextField), 'Alp');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('featuredStrip')), findsNothing);
    });

    testWidgets('a pick opens its page', (tester) async {
      final app = await open(tester, all: all, featured: [_r('d', 'Delta')]);

      await tester.tap(find.byKey(const Key('featured-d')));
      await tester.pumpAndSettle();

      expect(app.currentPath, '/restaurants/d');
    });

    testWidgets('the picks can be several, side by side', (tester) async {
      await open(tester, all: all, featured: [_r('a', 'Alpha'), _r('d', 'Delta')]);

      expect(find.byKey(const Key('featured-a')), findsOneWidget);
      expect(find.byKey(const Key('featured-d')), findsOneWidget);
    });
  });
}
