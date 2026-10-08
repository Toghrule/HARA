import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/l10n/app_localizations.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurant_sort.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:hara/features/restaurants/presentation/screens/restaurants_screen.dart';

typedef _Call = ({RestaurantSort sort, String search, int page, int pageSize});

/// Behaves like the real endpoint: filters by name/address, sorts by name, and cuts out one page.
class _FakeRestaurantsRepository extends RestaurantsRepository {
  _FakeRestaurantsRepository(this.all) : super(ApiClient());

  final List<Restaurant> all;
  final List<_Call> calls = [];

  /// Pages that fail the first time they are requested.
  final Set<int> failOncePages = {};

  /// While set, requests for page 2 wait for it, to simulate a slow connection.
  Completer<void>? gatePageTwo;

  /// Simulates an older server that doesn't know about paging and always returns everything.
  bool ignorePaging = false;

  @override
  Future<List<Restaurant>> getRestaurants({
    RestaurantSort sort = RestaurantSort.nameAsc,
    String search = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    calls.add((sort: sort, search: search, page: page, pageSize: pageSize));

    if (failOncePages.remove(page)) {
      throw DioException(requestOptions: RequestOptions(path: '/api/restaurants'));
    }
    if (page == 2 && gatePageTwo != null) await gatePageTwo!.future;

    final term = search.toLowerCase();
    var matches = all
        .where((r) => term.isEmpty || r.name.toLowerCase().contains(term) || r.address.toLowerCase().contains(term))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    if (sort == RestaurantSort.nameDesc) matches = matches.reversed.toList();

    if (ignorePaging) return matches;

    return matches.skip((page - 1) * pageSize).take(pageSize).toList();
  }
}

List<Restaurant> _restaurants(int count) => List.generate(count, (index) {
      final number = (index + 1).toString().padLeft(2, '0');

      return Restaurant(
        id: 'r$number',
        name: 'Test Restoran $number',
        address: 'Street $number',
        latitude: 1,
        longitude: 1,
      );
    });

Future<_FakeRestaurantsRepository> _pumpHome(
  WidgetTester tester, {
  int count = 45,
  bool ignorePaging = false,
}) async {
  tester.view.physicalSize = const Size(500, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = _FakeRestaurantsRepository(_restaurants(count))..ignorePaging = ignorePaging;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [restaurantsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const RestaurantsScreen()),
    ),
  );
  await tester.pumpAndSettle();

  return repository;
}

/// Drags the list up until [until] is on screen. Pumps by time rather than settling, because a
/// "loading more" spinner keeps animating while a request is in flight.
Future<void> _scrollUntil(WidgetTester tester, Finder until) async {
  for (var i = 0; i < 40 && until.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 450)); // past the typing pause
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('loads the first page of 20 and shows the restaurants', (tester) async {
    final repository = await _pumpHome(tester);

    expect(repository.calls, hasLength(1));
    expect(repository.calls.single.page, 1);
    expect(repository.calls.single.pageSize, 20);
    expect(find.text('Test Restoran 01'), findsOneWidget);
    expect(find.text('Test Restoran 25'), findsNothing); // beyond page 1
  });

  testWidgets('scrolling to the end loads each further page once, then the list simply ends', (tester) async {
    final repository = await _pumpHome(tester);

    await _scrollUntil(tester, find.text('Test Restoran 45'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.calls.map((c) => c.page).toList(), [1, 2, 3]);
    expect(find.text('Test Restoran 45'), findsOneWidget); // the very last one arrived
    expect(find.text('Own a restaurant?'), findsNothing, reason: 'owners register from the account button, not from the customer list');
  });

  testWidgets('a server that ignores paging does not make the list repeat itself', (tester) async {
    // 25 restaurants come back for page 1 (more than a page), and the same 25 for page 2.
    final repository = await _pumpHome(tester, count: 25, ignorePaging: true);

    await _scrollUntil(tester, find.text('Test Restoran 25'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.calls.map((c) => c.page).toList(), [1, 2]); // stops once page 2 adds nothing new
    expect(find.text('Test Restoran 25'), findsOneWidget);

    // Scroll back to the top: the first restaurant is there exactly once.
    await tester.drag(find.byType(ListView), const Offset(0, 20000));
    await tester.pumpAndSettle();
    expect(find.text('Test Restoran 01'), findsOneWidget);
  });

  testWidgets('a list that fits on one page loads no more', (tester) async {
    final repository = await _pumpHome(tester, count: 5);

    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.calls, hasLength(1));
    expect(find.text('Test Restoran 05'), findsOneWidget);
    expect(find.text('Own a restaurant?'), findsNothing);
  });

  testWidgets('searching waits for a pause in typing, then restarts from page 1', (tester) async {
    final repository = await _pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'res');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'restoran 07');
    await tester.pump(const Duration(milliseconds: 200));
    expect(repository.calls, hasLength(1)); // still only the initial load

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(repository.calls, hasLength(2));
    expect(repository.calls.last.search, 'restoran 07');
    expect(repository.calls.last.page, 1);
    expect(find.text('Test Restoran 07'), findsOneWidget);
    expect(find.text('Test Restoran 01'), findsNothing);
  });

  testWidgets('a new search replaces the list, even after later pages were loaded', (tester) async {
    final repository = await _pumpHome(tester);
    await _scrollUntil(tester, find.text('Test Restoran 21'));
    expect(repository.calls.map((c) => c.page), contains(2));

    await _type(tester, 'restoran 03');

    expect(repository.calls.last.search, 'restoran 03');
    expect(repository.calls.last.page, 1);
    expect(find.text('Test Restoran 03'), findsOneWidget);
    expect(find.text('Test Restoran 21'), findsNothing);
  });

  testWidgets('says when nothing matches and "Clear search" brings the list back', (tester) async {
    final repository = await _pumpHome(tester);

    await _type(tester, 'zzz');

    expect(find.text('No restaurants match "zzz".'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(repository.calls.last.search, '');
    expect(find.text('Test Restoran 01'), findsOneWidget);
  });

  testWidgets('the clear button in the search box only shows while there is text', (tester) async {
    await _pumpHome(tester);

    expect(find.byTooltip('Clear search'), findsNothing);

    await _type(tester, 'restoran');
    expect(find.byTooltip('Clear search'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear search'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('changing the sort starts again from page 1', (tester) async {
    final repository = await _pumpHome(tester);
    await _scrollUntil(tester, find.text('Test Restoran 21'));

    await tester.tap(find.text('A-Z'));
    await tester.pumpAndSettle();

    expect(repository.calls.last.sort, RestaurantSort.nameDesc);
    expect(repository.calls.last.page, 1);
    expect(find.text('Test Restoran 45'), findsOneWidget); // descending: the highest number first
  });

  testWidgets('a failed page shows a retry, keeps what was loaded, and does not retry on its own', (tester) async {
    final repository = await _pumpHome(tester);
    repository.failOncePages.add(2);

    await _scrollUntil(tester, find.textContaining('Couldn\'t load more restaurants.'));
    expect(find.textContaining('Couldn\'t load more restaurants.'), findsOneWidget);
    expect(find.text('Test Restoran 01'), findsNothing); // scrolled past, but still in the list
    final callsAfterFailure = repository.calls.length;

    await tester.pump(const Duration(seconds: 2));
    expect(repository.calls, hasLength(callsAfterFailure)); // no automatic retry loop

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.calls.map((c) => c.page).toList(), [1, 2, 2]);
    expect(find.textContaining('Couldn\'t load more restaurants.'), findsNothing);
  });

  testWidgets('a slow page for the old search is not added to the new results', (tester) async {
    final repository = await _pumpHome(tester);
    repository.gatePageTwo = Completer<void>();

    await _scrollUntil(tester, find.byType(CircularProgressIndicator)); // page 2 is now in flight
    expect(repository.calls.map((c) => c.page), contains(2));

    // 33 is on neither page 1 nor page 2 of the old list, so it can only show up through the new search.
    await _type(tester, 'restoran 33');
    expect(find.text('Test Restoran 33'), findsOneWidget);

    repository.gatePageTwo!.complete(); // the old page 2 finally arrives
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Only the one match. If the late page were merged in, the old restaurants would be back and there
    // would be many more rows.
    expect(find.text('Test Restoran 33'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(1));
  });
}
