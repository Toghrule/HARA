import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurant_sort.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:hara/main.dart';

class _FakeRestaurantsRepository extends RestaurantsRepository {
  _FakeRestaurantsRepository() : super(ApiClient());

  @override
  Future<List<Restaurant>> getRestaurants(RestaurantSort sort) async => const [];
}

void main() {
  testWidgets('renders the HARA app bar and the empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restaurantsRepositoryProvider.overrideWithValue(_FakeRestaurantsRepository()),
        ],
        child: const HaraApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HARA'), findsOneWidget);
    expect(find.text('No restaurants yet.'), findsOneWidget);
  });
}
