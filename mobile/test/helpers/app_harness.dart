import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hara/core/auth/auth_controller.dart';
import 'package:hara/core/auth/auth_repository.dart';
import 'package:hara/core/auth/auth_session.dart';
import 'package:hara/core/auth/session_storage.dart';
import 'package:hara/core/l10n/locale_provider.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/core/router/app_router.dart';
import 'package:hara/features/auth/data/customer_choice.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/data/restaurant_sort.dart';
import 'package:hara/features/restaurants/data/restaurants_repository.dart';
import 'package:hara/features/venue/data/venue_repository.dart';
import 'package:hara/main.dart';

AuthSession testSession({
  String access = 'access-1',
  String refresh = 'refresh-1',
  List<String> roles = const ['Owner'],
}) =>
    AuthSession(
      accessToken: access,
      accessExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
      refreshToken: refresh,
      roles: roles,
    );

class MemorySessionStorage implements SessionStorage {
  MemorySessionStorage([this.saved]);

  AuthSession? saved;

  @override
  Future<AuthSession?> read() async => saved;

  @override
  Future<void> write(AuthSession session) async => saved = session;

  @override
  Future<void> clear() async => saved = null;
}

DioException serverError(int status, [Object? data]) {
  final options = RequestOptions(path: '/x');

  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

/// Records every sign-in / registration and answers from a script.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository();

  final List<Map<String, Object?>> calls = [];
  final List<String> logoutCalls = [];

  Object? error;
  AuthSession session = testSession();

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    calls.add({'call': 'login', 'email': email, 'password': password});
    if (error != null) throw error!;

    return session;
  }

  @override
  Future<AuthSession> registerOwner({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    required String restaurantName,
    required String address,
    String? restaurantPhoneNumber,
    String? description,
  }) async {
    calls.add({
      'call': 'registerOwner',
      'email': email,
      'password': password,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'restaurantName': restaurantName,
      'address': address,
      'restaurantPhoneNumber': restaurantPhoneNumber,
      'description': description,
    });
    if (error != null) throw error!;

    return session;
  }

  @override
  Future<AuthSession> registerStaff({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    required String restaurantId,
  }) async {
    calls.add({
      'call': 'registerStaff',
      'email': email,
      'password': password,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'restaurantId': restaurantId,
    });
    if (error != null) throw error!;

    return session;
  }

  @override
  Future<AuthSession?> refresh(String refreshToken) async => session;

  @override
  Future<void> logout(String refreshToken) async => logoutCalls.add(refreshToken);
}

class FakeRestaurantsRepository extends RestaurantsRepository {
  FakeRestaurantsRepository(this.all) : super(ApiClient());

  final List<Restaurant> all;

  @override
  Future<List<Restaurant>> getRestaurants({
    RestaurantSort sort = RestaurantSort.nameAsc,
    String search = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    final term = search.trim().toLowerCase();

    return all.where((restaurant) => term.isEmpty || restaurant.name.toLowerCase().contains(term)).take(pageSize).toList();
  }
}

const cafeOne = Restaurant(
  id: 'rest-1',
  name: 'Cafe One',
  address: 'Baku, Nizami 1',
  latitude: 40.4,
  longitude: 49.8,
  discountPercent: 10,
);

const cafeTwo = Restaurant(
  id: 'rest-2',
  name: 'Bistro Two',
  address: 'Baku, Fizuli 2',
  latitude: 40.4,
  longitude: 49.8,
  discountPercent: 0,
);

/// Starts the real app (real router, real screens) in English with fake servers behind it.
class AppHarness {
  AppHarness({
    this.session,
    this.continuedAsCustomer = false,
    List<Restaurant>? restaurants,
    this.venueRepository,
  })  : auth = FakeAuthRepository(),
        storage = MemorySessionStorage(session),
        restaurants = FakeRestaurantsRepository(restaurants ?? const [cafeOne, cafeTwo]);

  final AuthSession? session;
  final bool continuedAsCustomer;
  final VenueRepository? venueRepository;
  final FakeAuthRepository auth;
  final MemorySessionStorage storage;
  final FakeRestaurantsRepository restaurants;

  late ProviderContainer container;

  GoRouter get router => container.read(appRouterProvider);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith((ref) => LocaleController(const Locale('en'))),
          customerChoiceProvider.overrideWith((ref) => CustomerChoice(continuedAsCustomer)),
          authControllerProvider.overrideWith((ref) => AuthController(auth, storage, session)),
          restaurantsRepositoryProvider.overrideWithValue(restaurants),
          if (venueRepository != null) venueRepositoryProvider.overrideWithValue(venueRepository!),
        ],
        child: const HaraApp(),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(tester.element(find.byType(HaraApp)));
  }

  /// Where the app is right now, e.g. `/venue`.
  String get currentPath => container.read(appRouterProvider).routerDelegate.currentConfiguration.last.matchedLocation;
}
