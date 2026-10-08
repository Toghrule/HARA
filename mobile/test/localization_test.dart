import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/l10n/locale_provider.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurant_sort.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:hara/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyRestaurantsRepository extends RestaurantsRepository {
  _EmptyRestaurantsRepository() : super(ApiClient());

  @override
  Future<List<Restaurant>> getRestaurants({
    RestaurantSort sort = RestaurantSort.nameAsc,
    String search = '',
    int page = 1,
    int pageSize = 20,
  }) async =>
      const [];
}

Set<String> _keys(String language) {
  final json = jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync()) as Map<String, dynamic>;

  return json.keys.where((key) => !key.startsWith('@')).toSet();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('translations', () {
    test('Azerbaijani and Russian have exactly the same texts as English', () {
      final english = _keys('en');

      expect(_keys('az').difference(english), isEmpty, reason: 'az has texts English lacks');
      expect(english.difference(_keys('az')), isEmpty, reason: 'az is missing texts');
      expect(_keys('ru').difference(english), isEmpty, reason: 'ru has texts English lacks');
      expect(english.difference(_keys('ru')), isEmpty, reason: 'ru is missing texts');
    });
  });

  group('starting language', () {
    test('uses the phone language when the app speaks it', () async {
      expect((await loadInitialLocale(deviceLocale: const Locale('ru', 'RU'))).languageCode, 'ru');
      expect((await loadInitialLocale(deviceLocale: const Locale('en', 'US'))).languageCode, 'en');
      expect((await loadInitialLocale(deviceLocale: const Locale('az', 'AZ'))).languageCode, 'az');
    });

    test('falls back to Azerbaijani for any other phone language', () async {
      expect((await loadInitialLocale(deviceLocale: const Locale('de', 'DE'))).languageCode, 'az');
    });

    test('a language the user picked wins over the phone language', () async {
      SharedPreferences.setMockInitialValues({'language': 'en'});

      expect((await loadInitialLocale(deviceLocale: const Locale('ru'))).languageCode, 'en');
    });

    test('ignores a saved language the app does not speak', () async {
      SharedPreferences.setMockInitialValues({'language': 'xx'});

      expect((await loadInitialLocale(deviceLocale: const Locale('ru'))).languageCode, 'ru');
    });
  });

  group('choosing a language', () {
    test('changes the language, remembers it and tells the server', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(apiClientProvider).dio.options.queryParameters['lang'], 'az');

      await container.read(localeProvider.notifier).select('ru');

      expect(container.read(localeProvider).languageCode, 'ru');
      expect(container.read(apiClientProvider).dio.options.queryParameters['lang'], 'ru');
      expect((await SharedPreferences.getInstance()).getString('language'), 'ru');
    });

    test('ignores a language the app does not speak', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).select('xx');

      expect(container.read(localeProvider).languageCode, 'az');
    });
  });

  testWidgets('the language menu switches the whole screen between the three languages', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restaurantsRepositoryProvider.overrideWithValue(_EmptyRestaurantsRepository()),
          localeProvider.overrideWith((ref) => LocaleController(const Locale('en'))),
        ],
        child: const HaraApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No restaurants yet.'), findsOneWidget);

    Future<void> choose(String name) async {
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, name));
      await tester.pumpAndSettle();
    }

    await choose('Русский');
    expect(find.text('Ресторанов пока нет.'), findsOneWidget);

    await choose('Azərbaycanca');
    expect(find.text('Hələ restoran yoxdur.'), findsOneWidget);

    await choose('English');
    expect(find.text('No restaurants yet.'), findsOneWidget);
  });
}
