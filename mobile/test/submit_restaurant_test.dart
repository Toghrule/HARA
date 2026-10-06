import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurant_sort.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:hara/features/restaurants/presentation/screens/restaurants_screen.dart';
import 'package:hara/features/submissions/data/submissions_repository.dart';
import 'package:hara/features/submissions/presentation/screens/submit_restaurant_screen.dart';

class _FakeSubmissionsRepository extends SubmissionsRepository {
  _FakeSubmissionsRepository({this.error}) : super(ApiClient());

  final Object? error;
  final List<Map<String, String?>> calls = [];

  @override
  Future<void> create({
    required String restaurantName,
    String? address,
    String? phoneNumber,
    String? description,
    required String submitterName,
    String? submitterEmail,
    String? submitterPhoneNumber,
  }) async {
    if (error != null) throw error!;
    calls.add({
      'restaurantName': restaurantName,
      'address': address,
      'phoneNumber': phoneNumber,
      'description': description,
      'submitterName': submitterName,
      'submitterEmail': submitterEmail,
      'submitterPhoneNumber': submitterPhoneNumber,
    });
  }
}

class _FakeRestaurantsRepository extends RestaurantsRepository {
  _FakeRestaurantsRepository() : super(ApiClient());

  @override
  Future<List<Restaurant>> getRestaurants(RestaurantSort sort) async => const [
        Restaurant(id: 'r1', name: 'Only One', address: 'Somewhere 1', latitude: 1, longitude: 1),
      ];
}

Future<void> _pumpForm(WidgetTester tester, _FakeSubmissionsRepository repository) {
  // Tall enough that the whole form is built without scrolling.
  tester.view.physicalSize = const Size(500, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  return tester.pumpWidget(
    ProviderScope(
      overrides: [submissionsRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: SubmitRestaurantScreen()),
    ),
  );
}

Future<void> _fill(WidgetTester tester, String key, String text) =>
    tester.enterText(find.byKey(Key(key)), text);

Future<void> _send(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Send request'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty form asks for the required fields and sends nothing', (tester) async {
    final repository = _FakeSubmissionsRepository();
    await _pumpForm(tester, repository);

    await _send(tester);

    expect(find.text('This field is required'), findsNWidgets(2)); // restaurant name + your name
    expect(find.text('Add an email or a phone number so we can reach you.'), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('requires an email or a phone number', (tester) async {
    final repository = _FakeSubmissionsRepository();
    await _pumpForm(tester, repository);

    await _fill(tester, 'restaurantName', 'Plov House');
    await _fill(tester, 'submitterName', 'Aysel');
    await _send(tester);

    expect(find.text('Add an email or a phone number so we can reach you.'), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('rejects a malformed email', (tester) async {
    final repository = _FakeSubmissionsRepository();
    await _pumpForm(tester, repository);

    await _fill(tester, 'restaurantName', 'Plov House');
    await _fill(tester, 'submitterName', 'Aysel');
    await _fill(tester, 'submitterEmail', 'not-an-email');
    await _send(tester);

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('sends trimmed values (empty optionals as null) and shows a thank-you', (tester) async {
    final repository = _FakeSubmissionsRepository();
    await _pumpForm(tester, repository);

    await _fill(tester, 'restaurantName', '  Plov House ');
    await _fill(tester, 'address', 'Nizami st 1');
    await _fill(tester, 'submitterName', ' Aysel ');
    await _fill(tester, 'submitterPhone', '+994 50 111 22 33');
    await _send(tester);

    expect(repository.calls, hasLength(1));
    expect(repository.calls.single, {
      'restaurantName': 'Plov House',
      'address': 'Nizami st 1',
      'phoneNumber': null,
      'description': null,
      'submitterName': 'Aysel',
      'submitterEmail': null,
      'submitterPhoneNumber': '+994 50 111 22 33',
    });
    expect(find.text('Thank you!'), findsOneWidget);
    expect(find.textContaining('"Plov House"'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('shows the server error and keeps the form so the user can retry', (tester) async {
    final repository = _FakeSubmissionsRepository(
      error: DioException(
        requestOptions: RequestOptions(path: '/api/submissions'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/submissions'),
          statusCode: 400,
          data: {
            'title': 'Validation failed',
            'errors': {
              'RestaurantName': ['Name is already taken'],
            },
          },
        ),
      ),
    );
    await _pumpForm(tester, repository);

    await _fill(tester, 'restaurantName', 'Plov House');
    await _fill(tester, 'submitterName', 'Aysel');
    await _fill(tester, 'submitterEmail', 'aysel@example.com');
    await _send(tester);

    expect(find.text('Name is already taken'), findsOneWidget);
    expect(find.text('Thank you!'), findsNothing);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send request')).onPressed, isNotNull);
  });

  testWidgets('the restaurant list offers a way into the form', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [restaurantsRepositoryProvider.overrideWithValue(_FakeRestaurantsRepository())],
        child: const MaterialApp(home: RestaurantsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Only One'), findsOneWidget);
    expect(find.text('Own a restaurant?'), findsOneWidget);
  });
}
