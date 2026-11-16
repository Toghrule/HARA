import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/map/presentation/map_screen.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurant_filters.dart';
import 'package:hara/features/restaurants/data/restaurant_sort.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:hara/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends RestaurantsRepository {
  _Repo(this.all) : super(ApiClient());

  final List<Restaurant> all;
  int pageSizeAsked = 0;

  @override
  Future<List<Restaurant>> getRestaurants({
    RestaurantSort sort = RestaurantSort.nameAsc,
    String search = '',
    int page = 1,
    int pageSize = 20,
    RestaurantListQuery query = const RestaurantListQuery(),
  }) async {
    pageSizeAsked = pageSize;

    return all;
  }
}

Restaurant _r(String id, String name, {double lat = 40.4, double lng = 49.8, int discount = 0}) =>
    Restaurant(id: id, name: name, address: 'Baku, $name street', latitude: lat, longitude: lng, discountPercent: discount, cuisines: const ['kebab'], ratingAverage: 4.5, ratingCount: 10);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(_Repo, GoRouter)> open(WidgetTester tester, List<Restaurant> restaurants) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _Repo(restaurants);
    final router = GoRouter(
      initialLocation: '/map',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('home'))),
        GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
        GoRoute(path: '/restaurants/:id', builder: (context, state) => Scaffold(body: Text('page of ${state.pathParameters['id']}'))),
        GoRoute(path: '/about', builder: (context, state) => const Scaffold(body: Text('about'))),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restaurantsRepositoryProvider.overrideWithValue(repo),
          // No network in tests: no picture tiles.
          mapTilesProvider.overrideWithValue(false),
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

    return (repo, router);
  }

  testWidgets('shows a pin for every place that has a position', (tester) async {
    await open(tester, [_r('a', 'Alpha', discount: 15), _r('b', 'Bravo', lat: 40.41, lng: 49.81), _r('c', 'Nowhere', lat: 0, lng: 0)]);

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byKey(const Key('pin-a')), findsOneWidget);
    expect(find.byKey(const Key('pin-b')), findsOneWidget);
    expect(find.byKey(const Key('pin-c')), findsNothing, reason: 'a place without coordinates (0,0 = not set) has no pin');
    expect(find.text('-15%'), findsOneWidget);
  });

  testWidgets('asks for every place at once, without filters', (tester) async {
    final (repo, _) = await open(tester, [_r('a', 'Alpha')]);

    expect(repo.pageSizeAsked, 100);
  });

  testWidgets('tapping a pin shows the place, and the card opens its page', (tester) async {
    final (_, router) = await open(tester, [_r('a', 'Alpha', discount: 15), _r('b', 'Bravo', lat: 40.41, lng: 49.81)]);
    expect(find.byKey(const Key('placeCard')), findsNothing);

    await tester.tap(find.byKey(const Key('pin-b')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('placeCard')), findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('placeCard')));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.last.matchedLocation, '/restaurants/b');
  });

  testWidgets('the map is the selected place of the bottom bar, and the other places lead away', (tester) async {
    final (_, router) = await open(tester, [_r('a', 'Alpha')]);

    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 2);

    await tester.tap(find.byKey(const Key('nav-more')));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation, '/about');
  });

  testWidgets('credits OpenStreetMap', (tester) async {
    await open(tester, [_r('a', 'Alpha')]);

    expect(find.byType(RichAttributionWidget), findsOneWidget);
  });
}
