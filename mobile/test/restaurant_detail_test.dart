import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:hara/features/restaurants/presentation/maps_launcher.dart';
import 'package:hara/features/restaurants/presentation/screens/restaurant_detail_screen.dart';

class _FakeRestaurantsRepository extends RestaurantsRepository {
  _FakeRestaurantsRepository(this._onGet) : super(ApiClient());

  final Future<Restaurant> Function(String id) _onGet;

  @override
  Future<Restaurant> getRestaurant(String id) => _onGet(id);
}

const _full = Restaurant(
  id: 'rest1',
  name: 'Mixek Restoran',
  address: 'Ehmedli, Hadi st',
  latitude: 40.4,
  longitude: 49.8,
  discountPercent: 15,
  phoneNumber: '+994 50 999 77 77',
  description: 'Breakfast, burgers and plov.',
);

Future<void> pumpDetail(WidgetTester tester, Future<Restaurant> Function(String id) onGet) {
  // Phone-sized, so the 16:9 cover image doesn't push the details out of the viewport.
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  return tester.pumpWidget(
    ProviderScope(
      overrides: [restaurantsRepositoryProvider.overrideWithValue(_FakeRestaurantsRepository(onGet))],
      child: const MaterialApp(home: RestaurantDetailScreen(restaurantId: 'rest1')),
    ),
  );
}

void main() {
  group('googleMapsUri', () {
    test('uses the exact coordinates when they are set', () {
      expect(googleMapsUri(_full).queryParameters['query'], '40.4,49.8');
    });

    test('falls back to an address search while the coordinates are still 0,0', () {
      const unset = Restaurant(id: 'a', name: 'A', address: 'Nizami st 1', latitude: 0, longitude: 0);

      expect(unset.hasCoordinates, isFalse);
      expect(googleMapsUri(unset).queryParameters['query'], 'Nizami st 1');
    });
  });

  test('imageUri resolves the API-relative upload path to a full URL', () {
    const restaurant = Restaurant(
      id: 'a',
      name: 'A',
      address: 'x',
      latitude: 1,
      longitude: 1,
      imageUrl: '/uploads/restaurants/a.png',
    );

    expect(restaurant.imageUri.toString(), 'http://localhost:5080/uploads/restaurants/a.png');
    expect(_full.imageUri, isNull);
  });

  testWidgets('shows the restaurant details and a reserve button', (tester) async {
    await pumpDetail(tester, (_) async => _full);
    await tester.pumpAndSettle();

    expect(find.text('Mixek Restoran'), findsNWidgets(2)); // app bar + heading
    expect(find.text('Ehmedli, Hadi st'), findsOneWidget);
    expect(find.text('+994 50 999 77 77'), findsOneWidget);
    expect(find.text('Breakfast, burgers and plov.'), findsOneWidget);
    expect(find.text('15% off with a reservation code'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant), findsOneWidget); // no cover image -> placeholder
    expect(find.widgetWithText(FilledButton, 'Reserve a table'), findsOneWidget);
  });

  testWidgets('hides the sections a restaurant has no data for', (tester) async {
    const bare = Restaurant(id: 'rest1', name: 'Bare', address: 'Somewhere 1', latitude: 1, longitude: 1);
    await pumpDetail(tester, (_) async => bare);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.phone_outlined), findsNothing);
    expect(find.byType(Chip), findsNothing);
  });

  testWidgets('tapping reserve opens the reservation sheet', (tester) async {
    await pumpDetail(tester, (_) async => _full);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Reserve a table'));
    await tester.pumpAndSettle();

    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
  });

  testWidgets('shows a friendly message when the restaurant no longer exists', (tester) async {
    await pumpDetail(tester, (_) async {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/restaurants/rest1'),
        response: Response(requestOptions: RequestOptions(path: ''), statusCode: 404),
      );
    });
    await tester.pumpAndSettle();

    expect(find.text('This restaurant is no longer available.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Reserve a table'), findsNothing);
  });
}
