import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';

Restaurant _r(String id, String name, {int discount = 0, double? rating, int ratingCount = 0}) => Restaurant(
      id: id,
      name: name,
      address: 'Baku, $name street',
      latitude: 40.4,
      longitude: 49.8,
      discountPercent: discount,
      cuisines: const ['kebab'],
      ratingAverage: rating,
      ratingCount: ratingCount,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AppHarness> open(WidgetTester tester, List<Restaurant> restaurants) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = AppHarness(continuedAsCustomer: true, restaurants: restaurants);
    await app.pump(tester);

    return app;
  }

  group('the bottom bar', () {
    testWidgets('has Discover, Favourites and More, with Discover selected', (tester) async {
      await open(tester, [_r('a', 'Alpha')]);

      expect(find.byKey(const Key('nav-discover')), findsOneWidget);
      expect(find.byKey(const Key('nav-favorites')), findsOneWidget);
      expect(find.byKey(const Key('nav-more')), findsOneWidget);
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);
    });

    testWidgets('Favourites shows only the hearted places and is the selected one', (tester) async {
      SharedPreferences.setMockInitialValues({
        'favorite_restaurants': ['a'],
      });
      await open(tester, [_r('a', 'Alpha'), _r('b', 'Bravo')]);

      await tester.tap(find.byKey(const Key('nav-favorites')));
      await tester.pumpAndSettle();

      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Bravo'), findsNothing);
    });

    testWidgets('Discover brings the whole list back', (tester) async {
      SharedPreferences.setMockInitialValues({
        'favorite_restaurants': ['a'],
      });
      await open(tester, [_r('a', 'Alpha'), _r('b', 'Bravo')]);
      await tester.tap(find.byKey(const Key('nav-favorites')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('nav-discover')));
      await tester.pumpAndSettle();

      expect(find.text('Bravo'), findsOneWidget);
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);
    });

    testWidgets('More opens the About screen, with the bar still there', (tester) async {
      final app = await open(tester, [_r('a', 'Alpha')]);

      await tester.tap(find.byKey(const Key('nav-more')));
      await tester.pumpAndSettle();

      expect(app.currentPath, '/about');
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 3);

      await tester.tap(find.byKey(const Key('nav-discover')));
      await tester.pumpAndSettle();
      expect(app.currentPath, '/');
    });
  });

  group('the discounts row', () {
    testWidgets('shows the places that give a discount when there are enough of them', (tester) async {
      await open(tester, [_r('a', 'Alpha', discount: 10), _r('b', 'Bravo', discount: 15), _r('c', 'Charlie', discount: 20), _r('d', 'Delta')]);

      expect(find.byKey(const Key('discountStrip')), findsOneWidget);
      expect(find.text('Discounts'), findsOneWidget);
      expect(find.byKey(const Key('strip-a')), findsOneWidget);
      expect(find.byKey(const Key('strip-d')), findsNothing);
    });

    testWidgets('is not shown for a couple of places (it would only repeat the list)', (tester) async {
      await open(tester, [_r('a', 'Alpha', discount: 10), _r('b', 'Bravo', discount: 15)]);

      expect(find.byKey(const Key('discountStrip')), findsNothing);
    });

    testWidgets('goes away while searching', (tester) async {
      await open(tester, [_r('a', 'Alpha', discount: 10), _r('b', 'Bravo', discount: 15), _r('c', 'Charlie', discount: 20)]);
      expect(find.byKey(const Key('discountStrip')), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Alp');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('discountStrip')), findsNothing);
    });

    testWidgets('tapping a place in the row opens its page', (tester) async {
      final app = await open(tester, [_r('a', 'Alpha', discount: 10), _r('b', 'Bravo', discount: 15), _r('c', 'Charlie', discount: 20)]);

      await tester.tap(find.byKey(const Key('strip-b')));
      await tester.pumpAndSettle();

      expect(app.currentPath, '/restaurants/b');
    });
  });

  group('the cards', () {
    testWidgets('show the rating beside the name, the cuisine and the discount', (tester) async {
      await open(tester, [_r('a', 'Alpha', discount: 15, rating: 4.6, ratingCount: 12)]);

      expect(find.text('4.6'), findsOneWidget);
      expect(find.text(' (12)'), findsOneWidget);
      expect(find.text('-15%'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('tile-info-a'))).data, contains('Kebab'));
    });

    testWidgets('show no rating while nobody has rated', (tester) async {
      await open(tester, [_r('a', 'Alpha')]);

      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });
  });
}
