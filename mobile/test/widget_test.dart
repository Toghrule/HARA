import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/features/auth/data/customer_choice.dart';
import 'package:hara/core/l10n/locale_provider.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurant_sort.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:hara/main.dart';

class _FakeRestaurantsRepository extends RestaurantsRepository {
  _FakeRestaurantsRepository() : super(ApiClient());

  @override
  Future<List<Restaurant>> getRestaurants({
    RestaurantSort sort = RestaurantSort.nameAsc,
    String search = '',
    int page = 1,
    int pageSize = 20,
  }) async =>
      const [];
}

void main() {
  testWidgets('renders the HARA app bar and the empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restaurantsRepositoryProvider.overrideWithValue(_FakeRestaurantsRepository()),
          localeProvider.overrideWith((ref) => LocaleController(const Locale('en'))),
          customerChoiceProvider.overrideWith((ref) => CustomerChoice(true)),
        ],
        child: const HaraApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HARA'), findsOneWidget);
    expect(find.text('No restaurants yet.'), findsOneWidget);
  });
}
