import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/location/location_service.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/restaurants/data/opening_hours.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurant_filters.dart';
import 'package:hara/features/restaurants/data/restaurant_sort.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:hara/features/restaurants/presentation/distance_text.dart';
import 'package:hara/features/restaurants/presentation/widgets/restaurant_filter_bar.dart';
import 'package:hara/l10n/app_localizations_az.dart';
import 'package:hara/l10n/app_localizations_en.dart';
import 'package:hara/l10n/app_localizations_ru.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';

/// Remembers what the app asked the server, and answers with an empty list.
class _CaptureAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);

    return ResponseBody.fromString('[]', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

const _closed = Availability(acceptingRequests: false, reason: AvailabilityReason.closed, nextOpensInDays: 1, nextOpensDay: 5, nextOpensAt: '10:00');

Restaurant _r(
  String id,
  String name, {
  double lat = 40.4,
  double lng = 49.8,
  List<String> cuisines = const [],
  Availability availability = Availability.open,
  String? imageUrl,
  List<String> gallery = const [],
}) =>
    Restaurant(
      id: id,
      name: name,
      address: 'Baku, $name street',
      latitude: lat,
      longitude: lng,
      cuisines: cuisines,
      availability: availability,
      imageUrl: imageUrl,
      galleryUrls: gallery,
    );

// Alpha is right where the phone is, Bravo a few km away, Charlie far.
final _alpha = _r('a', 'Alpha Grill', cuisines: ['kebab', 'azerbaijani']);
final _bravo = _r('b', 'Bravo Pizza', lat: 40.43, lng: 49.83, cuisines: ['pizza', 'italian'], availability: _closed);
final _charlie = _r('c', 'Charlie Cafe', lat: 40.7, lng: 50.1, cuisines: ['cafe']);

const _here = UserPosition(latitude: 40.4, longitude: 49.8);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AppHarness> open(WidgetTester tester, {List<Restaurant>? restaurants, LocationService? location}) async {
    final app = AppHarness(continuedAsCustomer: true, restaurants: restaurants ?? [_alpha, _bravo, _charlie], locationService: location);
    await app.pump(tester);

    return app;
  }

  Future<void> tapChip(WidgetTester tester, String key) async {
    final chip = find.byKey(Key(key));
    // The chips are a long row that builds as it scrolls: swipe it until the one wanted is on screen.
    final row = find.descendant(of: find.byType(RestaurantFilterBar), matching: find.byType(Scrollable));
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    for (var i = 0; i < 20 && (chip.evaluate().isEmpty || tester.getCenter(chip).dx > width - 60); i++) {
      await tester.drag(row, const Offset(-250, 0));
      await tester.pumpAndSettle();
    }
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  group('numbers and words', () {
    test('distance between two points', () {
      expect(distanceKm(_here, 40.4, 49.8), closeTo(0, 0.001));
      // One degree of latitude is about 111 km.
      expect(distanceKm(_here, 41.4, 49.8), closeTo(111.2, 0.5));
      expect(distanceKm(_here, 40.43, 49.83), closeTo(4.2, 0.2));
    });

    test('short distances are in metres, to the nearest ten, and never zero', () {
      final en = AppLocalizationsEn();

      expect(distanceText(en, 0.0004), '10 m');
      expect(distanceText(en, 0.347), '350 m');
      expect(distanceText(en, 0.999), '1000 m');
      expect(distanceText(en, 1.0), '1.0 km');
      expect(distanceText(en, 4.24), '4.2 km');
      expect(distanceText(AppLocalizationsRu(), 4.24), '4.2 км');
    });

    test('cuisine names in all three languages', () {
      expect(AppLocalizationsEn().cuisineName('kebab'), 'Kebab and grill');
      expect(AppLocalizationsAz().cuisineName('dessert'), 'Desertlər');
      expect(AppLocalizationsRu().cuisineName('seafood'), 'Морепродукты');
      for (final code in cuisineCodes) {
        expect(AppLocalizationsEn().cuisineName(code), isNotEmpty, reason: code);
      }
    });

    test('the server answer: cuisines and photos, the cover first without repeats', () {
      final restaurant = Restaurant.fromJson({
        'id': 'x',
        'name': 'N',
        'address': 'A',
        'latitude': 1,
        'longitude': 2,
        'imageUrl': '/uploads/cover.jpg',
        'cuisines': ['kebab', 'cafe'],
        'galleryUrls': ['/uploads/cover.jpg', '/uploads/two.jpg'],
      });

      expect(restaurant.cuisines, ['kebab', 'cafe']);
      expect(restaurant.photoUris.map((u) => u.path.split('/').last), ['cover.jpg', 'two.jpg']);
    });

    test('an older server that sends neither has none', () {
      final restaurant = Restaurant.fromJson({'id': 'x', 'name': 'N', 'address': 'A', 'latitude': 1, 'longitude': 2});

      expect(restaurant.cuisines, isEmpty);
      expect(restaurant.photoUris, isEmpty);
    });
  });

  group('what is sent to the server', () {
    Future<Map<String, dynamic>> asked({RestaurantSort sort = RestaurantSort.nameAsc, RestaurantListQuery query = const RestaurantListQuery()}) async {
      final adapter = _CaptureAdapter();
      final client = ApiClient()..dio.httpClientAdapter = adapter;
      await RestaurantsRepository(client).getRestaurants(sort: sort, query: query);

      return adapter.requests.single.queryParameters;
    }

    test('an ordinary list sends none of the new filters', () async {
      final params = await asked();

      expect(params['sort'], 'name_asc');
      for (final key in ['openNow', 'cuisine', 'lat', 'lng', 'ids']) {
        expect(params.containsKey(key), isFalse, reason: key);
      }
    });

    test('every filter goes out under the name the server reads', () async {
      final params = await asked(
        sort: RestaurantSort.nearest,
        query: const RestaurantListQuery(openNow: true, cuisine: 'kebab', latitude: 40.4, longitude: 49.8, ids: ['a', 'b']),
      );

      expect(params['sort'], 'nearest');
      expect(params['openNow'], true);
      expect(params['cuisine'], 'kebab');
      expect(params['lat'], 40.4);
      expect(params['lng'], 49.8);
      expect(params['ids'], 'a,b');
    });

    test('a position is only sent together (never half of it)', () async {
      final params = await asked(query: const RestaurantListQuery(latitude: 40.4));

      expect(params.containsKey('lat'), isFalse);
      expect(params.containsKey('lng'), isFalse);
    });
  });

  group('filters', () {
    testWidgets('"open now" asks the server for open restaurants only and can be switched off again', (tester) async {
      final app = await open(tester);
      expect(find.text('Bravo Pizza'), findsOneWidget);

      await tapChip(tester, 'chip-open');

      expect(app.restaurants.queries.last.query.openNow, isTrue);
      expect(find.text('Bravo Pizza'), findsNothing); // closed
      expect(find.text('Alpha Grill'), findsOneWidget);

      await tapChip(tester, 'chip-open');

      expect(app.restaurants.queries.last.query.openNow, isFalse);
      expect(find.text('Bravo Pizza'), findsOneWidget);
    });

    testWidgets('a cuisine narrows the list; picking it again clears it; picking another replaces it', (tester) async {
      final app = await open(tester);

      await tapChip(tester, 'chip-cuisine-kebab');
      expect(app.restaurants.queries.last.query.cuisine, 'kebab');
      expect(find.text('Alpha Grill'), findsOneWidget);
      expect(find.text('Charlie Cafe'), findsNothing);

      await tapChip(tester, 'chip-cuisine-cafe');
      expect(app.restaurants.queries.last.query.cuisine, 'cafe');
      expect(find.text('Charlie Cafe'), findsOneWidget);
      expect(find.text('Alpha Grill'), findsNothing);

      await tapChip(tester, 'chip-cuisine-cafe');
      expect(app.restaurants.queries.last.query.cuisine, isNull);
      expect(find.text('Alpha Grill'), findsOneWidget);
    });

    testWidgets('filters add up, search keeps working with them, and "clear filters" undoes the narrowing', (tester) async {
      final app = await open(tester);

      await tapChip(tester, 'chip-open');
      await tapChip(tester, 'chip-cuisine-pizza'); // the only pizza place is closed

      expect(app.restaurants.queries.last.query.openNow, isTrue);
      expect(app.restaurants.queries.last.query.cuisine, 'pizza');
      expect(find.byKey(const Key('emptyMessage')), findsOneWidget);
      expect(find.text('No restaurants match these filters.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('clearFilters')));
      await tester.pumpAndSettle();

      expect(app.restaurants.queries.last.query.openNow, isFalse);
      expect(app.restaurants.queries.last.query.cuisine, isNull);
      expect(find.text('Bravo Pizza'), findsOneWidget);
    });
  });

  group('favourites', () {
    testWidgets('the heart marks a restaurant, saves it on the phone, and a second tap undoes it', (tester) async {
      await open(tester);

      await tester.tap(find.byKey(const Key('fav-a')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('fav-a')), matching: find.byIcon(Icons.favorite)), findsOneWidget);
      expect((await SharedPreferences.getInstance()).getStringList('favorite_restaurants'), ['a']);

      await tester.tap(find.byKey(const Key('fav-a')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('fav-a')), matching: find.byIcon(Icons.favorite_border)), findsOneWidget);
      expect((await SharedPreferences.getInstance()).getStringList('favorite_restaurants'), isEmpty);
    });

    testWidgets('hearts given earlier are still there next time the app opens', (tester) async {
      SharedPreferences.setMockInitialValues({
        'favorite_restaurants': ['c'],
      });
      await open(tester);

      expect(find.descendant(of: find.byKey(const Key('fav-c')), matching: find.byIcon(Icons.favorite)), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('fav-a')), matching: find.byIcon(Icons.favorite_border)), findsOneWidget);
    });

    testWidgets('the favourites filter shows only the hearted ones, asking the server for exactly those', (tester) async {
      SharedPreferences.setMockInitialValues({
        'favorite_restaurants': ['a', 'c'],
      });
      final app = await open(tester);

      await tapChip(tester, 'chip-favorites');

      expect(app.restaurants.queries.last.query.ids, unorderedEquals(['a', 'c']));
      expect(find.text('Alpha Grill'), findsOneWidget);
      expect(find.text('Charlie Cafe'), findsOneWidget);
      expect(find.text('Bravo Pizza'), findsNothing);

      // Un-hearting in this view takes the restaurant off the list.
      await tester.tap(find.byKey(const Key('fav-a')));
      await tester.pumpAndSettle();
      expect(find.text('Alpha Grill'), findsNothing);
      expect(app.restaurants.queries.last.query.ids, ['c']);
    });

    testWidgets('with no favourites the list says so, without asking the server', (tester) async {
      final app = await open(tester);
      final before = app.restaurants.queries.length;

      await tapChip(tester, 'chip-favorites');

      expect(find.text('No favorites yet. Tap the heart on a restaurant to keep it here.'), findsOneWidget);
      expect(app.restaurants.queries.length, before);
    });

    testWidgets('the restaurant page has a heart too, in step with the list', (tester) async {
      await open(tester);

      await tester.tap(find.text('Alpha Grill'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('favoriteButton')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('favoriteButton')), matching: find.byIcon(Icons.favorite)), findsOneWidget);
      expect((await SharedPreferences.getInstance()).getStringList('favorite_restaurants'), ['a']);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byKey(const Key('fav-a')), matching: find.byIcon(Icons.favorite)), findsOneWidget);
    });
  });

  group('location', () {
    testWidgets('a build without location offers none of it: no question, no "Nearest"', (tester) async {
      await open(tester);

      expect(find.byKey(const Key('locationExplain')), findsNothing);
      expect(find.byKey(const Key('chip-nearest')), findsNothing);
    });

    testWidgets('the first launch explains, and "Allow" asks the phone and shows distances', (tester) async {
      final location = FakeLocationService(at: _here);
      await open(tester, location: location);

      expect(find.byKey(const Key('locationExplain')), findsOneWidget);
      expect(find.text('Find restaurants near you'), findsOneWidget);
      expect(location.requests, 0); // nothing is asked before the person agrees

      await tester.tap(find.byKey(const Key('locationAllow')));
      await tester.pumpAndSettle();

      expect(location.requests, 1);
      expect(find.byKey(const Key('locationExplain')), findsNothing);
      expect(find.text('Baku, Alpha Grill street · 10 m'), findsOneWidget);
      expect(find.textContaining('Baku, Bravo Pizza street · 4.'), findsOneWidget);
      expect((await SharedPreferences.getInstance()).getBool('location_asked'), isTrue);
    });

    testWidgets('"Not now" asks the phone nothing, shows no distances, and the question does not come back', (tester) async {
      final location = FakeLocationService(at: _here);
      await open(tester, location: location);

      await tester.tap(find.byKey(const Key('locationNotNow')));
      await tester.pumpAndSettle();

      expect(location.requests, 0);
      expect(find.textContaining(' · '), findsNothing);
      expect((await SharedPreferences.getInstance()).getBool('location_asked'), isTrue);
    });

    testWidgets('someone already asked is not asked again on the next launch', (tester) async {
      SharedPreferences.setMockInitialValues({'location_asked': true});
      await open(tester, location: FakeLocationService(at: _here));

      expect(find.byKey(const Key('locationExplain')), findsNothing);
    });

    testWidgets('permission given earlier: distances show at once, with no question', (tester) async {
      SharedPreferences.setMockInitialValues({'location_asked': true});
      final location = FakeLocationService(currentAccess: LocationAccess.granted, at: _here);
      await open(tester, location: location);

      expect(find.byKey(const Key('locationExplain')), findsNothing);
      expect(location.requests, 0);
      expect(find.text('Baku, Alpha Grill street · 10 m'), findsOneWidget);
    });

    testWidgets('"Nearest" sorts by distance, sending the position', (tester) async {
      SharedPreferences.setMockInitialValues({'location_asked': true});
      final app = await open(tester, location: FakeLocationService(currentAccess: LocationAccess.granted, at: _here), restaurants: [_charlie, _bravo, _alpha]);

      await tapChip(tester, 'chip-nearest');

      final query = app.restaurants.queries.last;
      expect(query.sort, RestaurantSort.nearest);
      expect(query.query.latitude, 40.4);
      expect(query.query.longitude, 49.8);
      final order = ['Alpha Grill', 'Bravo Pizza', 'Charlie Cafe'].map((name) => tester.getTopLeft(find.text(name)).dy).toList();
      expect(order, orderedEquals([...order]..sort()));

      await tapChip(tester, 'chip-nearest');
      expect(app.restaurants.queries.last.sort, isNot(RestaurantSort.nearest));
      expect(app.restaurants.queries.last.query.latitude, isNull);
    });

    testWidgets('"Nearest" after saying "Not now" still works: it asks the phone then', (tester) async {
      final location = FakeLocationService(at: _here);
      final app = await open(tester, location: location);
      await tester.tap(find.byKey(const Key('locationNotNow')));
      await tester.pumpAndSettle();
      expect(location.requests, 0);

      await tapChip(tester, 'chip-nearest');

      expect(location.requests, 1);
      expect(app.restaurants.queries.last.sort, RestaurantSort.nearest);
    });

    testWidgets('if the phone\'s question is refused, nothing changes', (tester) async {
      SharedPreferences.setMockInitialValues({'location_asked': true});
      final location = FakeLocationService(onRequest: LocationAccess.denied);
      final app = await open(tester, location: location);
      final before = app.restaurants.queries.length;

      await tapChip(tester, 'chip-nearest');

      expect(location.requests, 1);
      expect(app.restaurants.queries.length, before);
      expect(tester.widget<FilterChip>(find.byKey(const Key('chip-nearest'))).selected, isFalse);
    });

    testWidgets('refused for good: says so and offers the phone\'s settings', (tester) async {
      SharedPreferences.setMockInitialValues({'location_asked': true});
      final location = FakeLocationService(currentAccess: LocationAccess.deniedForever);
      await open(tester, location: location);

      await tapChip(tester, 'chip-nearest');

      expect(find.text("Location is off for HARA. Turn it on in the phone's settings to sort by distance."), findsOneWidget);
      expect(location.requests, 0); // asking again would do nothing
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(location.settingsOpened, 1);
      expect(tester.widget<FilterChip>(find.byKey(const Key('chip-nearest'))).selected, isFalse);
    });

    testWidgets('the phone\'s location switch is off: says so', (tester) async {
      SharedPreferences.setMockInitialValues({'location_asked': true});
      await open(tester, location: FakeLocationService(currentAccess: LocationAccess.serviceOff));

      await tapChip(tester, 'chip-nearest');

      expect(find.text('Location is turned off on your phone. Turn it on to sort by distance.'), findsOneWidget);
    });

    testWidgets('permission given but no position found: says so instead of sorting by nothing', (tester) async {
      SharedPreferences.setMockInitialValues({'location_asked': true});
      final app = await open(tester, location: FakeLocationService(currentAccess: LocationAccess.granted));
      final before = app.restaurants.queries.length;

      await tapChip(tester, 'chip-nearest');

      expect(find.text("Couldn't find your location. Try again in a moment."), findsOneWidget);
      expect(app.restaurants.queries.length, before);
    });
  });

  group('the restaurant page', () {
    Future<void> openDetail(WidgetTester tester, Restaurant restaurant, {LocationService? location}) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(tester, restaurants: [restaurant], location: location);
      await tester.tap(find.text(restaurant.name));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the cuisines', (tester) async {
      await openDetail(tester, _alpha);

      expect(find.descendant(of: find.byKey(const Key('cuisines')), matching: find.text('Kebab and grill')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('cuisines')), matching: find.text('Azerbaijani')), findsOneWidget);
    });

    testWidgets('photos: the cover and the gallery swipe, with dots, and a tap opens one large', (tester) async {
      await openDetail(tester, _r('g', 'Gallery House', imageUrl: '/uploads/cover.jpg', gallery: ['/uploads/one.jpg', '/uploads/two.jpg']));

      expect(find.byKey(const Key('gallery')), findsOneWidget);
      expect(find.byKey(const Key('dot-active')), findsOneWidget);
      expect(find.byKey(const Key('dot-1')), findsOneWidget);
      expect(find.byKey(const Key('dot-2')), findsOneWidget);

      await tester.drag(find.byKey(const Key('gallery')), const Offset(-300, 0));
      await tester.pumpAndSettle();
      // The second photo is now the active one: the dots that are not active are the first and the third.
      expect(find.byKey(const Key('dot-0')), findsOneWidget);
      expect(find.byKey(const Key('dot-2')), findsOneWidget);
      expect(find.byKey(const Key('dot-1')), findsNothing);

      await tester.tap(find.byKey(const Key('photo-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('closePhoto')), findsOneWidget);

      await tester.tap(find.byKey(const Key('closePhoto')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('closePhoto')), findsNothing);
    });

    testWidgets('a single photo has no dots, and none at all shows the placeholder', (tester) async {
      await openDetail(tester, _r('s', 'Single Spot', imageUrl: '/uploads/cover.jpg'));
      expect(find.byKey(const Key('gallery')), findsOneWidget);
      expect(find.byKey(const Key('dot-active')), findsNothing);
    });

    testWidgets('no photos: the placeholder, no gallery', (tester) async {
      await openDetail(tester, _r('n', 'No Photos'));

      expect(find.byKey(const Key('gallery')), findsNothing);
      expect(find.byIcon(Icons.restaurant), findsWidgets);
    });

    testWidgets('how far it is, once the phone\'s position is known', (tester) async {
      SharedPreferences.setMockInitialValues({'location_asked': true});
      await openDetail(tester, _bravo, location: FakeLocationService(currentAccess: LocationAccess.granted, at: _here));

      expect(find.byKey(const Key('distance')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('distance'))).data, startsWith('4.'));
    });
  });
}
