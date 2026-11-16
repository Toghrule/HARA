import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/feature_flags.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurant_filters.dart';
import 'package:hara/features/restaurants/data/restaurant_sort.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:hara/features/restaurants/presentation/screens/restaurant_detail_screen.dart';
import 'package:hara/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';
import 'helpers/venue_fakes.dart';

class _Repo extends RestaurantsRepository {
  _Repo() : super(ApiClient());

  static const restaurant = Restaurant(id: 'rest1', name: 'Mixek Restoran', address: 'Baku', latitude: 40.4, longitude: 49.8, discountPercent: 15);

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
      const [restaurant];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => FeatureFlags.reservationsEnabled = false);

  test('reservations are off by default', () {
    expect(FeatureFlags.reservationsEnabled, isFalse);
  });

  Future<void> pumpDetail(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    return tester.pumpWidget(
      ProviderScope(
        overrides: [restaurantsRepositoryProvider.overrideWithValue(_Repo())],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const RestaurantDetailScreen(restaurantId: 'rest1'),
        ),
      ),
    );
  }

  group('the customer', () {
    testWidgets('sees no reserve button on the restaurant page while reservations are off', (tester) async {
      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('Mixek Restoran'), findsWidgets);
      expect(find.text('Reserve a table'), findsNothing);
      expect(find.byIcon(Icons.event_seat), findsNothing);
    });

    testWidgets('gets the reserve button back when the switch is turned on', (tester) async {
      FeatureFlags.reservationsEnabled = true;
      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('Reserve a table'), findsOneWidget);
    });
  });

  group('the restaurant side', () {
    Future<void> open(WidgetTester tester) async {
      final app = AppHarness(session: testSession(roles: ['Owner']), venueRepository: FakeVenueRepository(me: approvedOwner()));
      await app.pump(tester);
    }

    testWidgets('has no Requests or Reservations tab while reservations are off, but keeps the rest', (tester) async {
      await open(tester);

      expect(find.widgetWithText(Tab, 'Requests'), findsNothing);
      expect(find.widgetWithText(Tab, 'Reservations'), findsNothing);
      expect(find.widgetWithText(Tab, 'Confirm code'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Statistics'), findsOneWidget);
    });

    testWidgets('has them back when the switch is turned on', (tester) async {
      FeatureFlags.reservationsEnabled = true;
      await open(tester);

      expect(find.widgetWithText(Tab, 'Requests'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Reservations'), findsOneWidget);
    });
  });
}
