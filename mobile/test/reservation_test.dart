import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/reservations/data/reservation.dart';
import 'package:hara/features/reservations/data/reservations_repository.dart';
import 'package:hara/features/reservations/presentation/screens/reservation_code_screen.dart';
import 'package:hara/features/reservations/presentation/widgets/reserve_sheet.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';

class _FakeReservationsRepository extends ReservationsRepository {
  _FakeReservationsRepository({this.error}) : super(ApiClient());

  final Object? error;
  final List<({String restaurantId, String phoneNumber, int durationMinutes})> calls = [];

  @override
  Future<Reservation> create({
    required String restaurantId,
    required String phoneNumber,
    required int durationMinutes,
  }) async {
    if (error != null) throw error!;
    calls.add((restaurantId: restaurantId, phoneNumber: phoneNumber, durationMinutes: durationMinutes));
    return _reservation(expiresIn: Duration(minutes: durationMinutes));
  }
}

Reservation _reservation({required Duration expiresIn, int discountPercent = 15}) => Reservation(
      id: 'r1',
      restaurantId: 'rest1',
      restaurantName: 'Test Restoran',
      discountPercent: discountPercent,
      code: 'S68NRG',
      durationMinutes: 30,
      expiresAt: DateTime.now().add(expiresIn),
    );

const _restaurant = Restaurant(
  id: 'rest1',
  name: 'Test Restoran',
  address: 'Test st 1',
  latitude: 40.4,
  longitude: 49.8,
  discountPercent: 15,
);

void main() {
  test('Reservation.fromJson parses the API response, including 7-digit fractional seconds', () {
    final reservation = Reservation.fromJson({
      'id': '3096c22c-b101-48b4-a3f7-29826d52e32a',
      'restaurantId': 'dc675a44-8a24-47d8-ad55-36440bb2edbc',
      'restaurantName': 'ZZ Test Restoran',
      'discountPercent': 15,
      'phoneNumber': '+994 50 123 45 67',
      'code': 'S68NRG',
      'durationMinutes': 30,
      'createdAt': '2026-10-06T09:01:29.231886+00:00',
      'expiresAt': '2026-10-06T09:31:29.1872135+00:00',
      'status': 0,
      'redeemedAt': null,
    });

    expect(reservation.code, 'S68NRG');
    expect(reservation.discountPercent, 15);
    expect(reservation.expiresAt.toUtc(), DateTime.utc(2026, 10, 6, 9, 31, 29, 187, 213));
  });

  testWidgets('code screen shows the code, restaurant, discount and a countdown', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationCodeScreen(reservation: _reservation(expiresIn: const Duration(minutes: 29, seconds: 30))),
      ),
    );

    expect(find.text('S68NRG'), findsOneWidget);
    expect(find.text('Test Restoran'), findsOneWidget);
    expect(find.textContaining('15% off'), findsOneWidget);
    expect(find.textContaining('Valid for 29:'), findsOneWidget);
  });

  testWidgets('code screen shows an expired state once the window has elapsed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationCodeScreen(reservation: _reservation(expiresIn: const Duration(minutes: -1))),
      ),
    );

    expect(find.text('This reservation has expired'), findsOneWidget);
  });

  group('ReserveSheet', () {
    late _FakeReservationsRepository repository;
    Reservation? result;

    Future<void> openSheet(WidgetTester tester, {Object? error}) async {
      repository = _FakeReservationsRepository(error: error);
      result = null;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [reservationsRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showModalBottomSheet<Reservation>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const ReserveSheet(restaurant: _restaurant),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('rejects an invalid phone number without calling the API', (tester) async {
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.tap(find.widgetWithText(FilledButton, 'Reserve'));
      await tester.pumpAndSettle();

      expect(find.textContaining('valid phone number'), findsOneWidget);
      expect(repository.calls, isEmpty);
      expect(result, isNull);
    });

    testWidgets('creates a 60-minute reservation and returns it', (tester) async {
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), '+994 50 123 45 67');
      await tester.tap(find.text('60 min'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reserve'));
      await tester.pumpAndSettle();

      expect(repository.calls, hasLength(1));
      expect(repository.calls.single.restaurantId, 'rest1');
      expect(repository.calls.single.phoneNumber, '+994 50 123 45 67');
      expect(repository.calls.single.durationMinutes, 60);
      expect(result?.code, 'S68NRG');
    });

    testWidgets('shows the server\'s reason when the reservation is refused and lets the user retry', (tester) async {
      final options = RequestOptions(path: '/api/reservations');
      await openSheet(
        tester,
        error: DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 400,
            data: {
              'title': 'Validation failed',
              'errors': {
                'PhoneNumber': ['This phone number already has an active reservation.'],
              },
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '+994 50 123 45 67');
      await tester.tap(find.widgetWithText(FilledButton, 'Reserve'));
      await tester.pumpAndSettle();

      expect(find.text('This phone number already has an active reservation.'), findsOneWidget);
      expect(result, isNull);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Reserve')).onPressed, isNotNull);
    });
  });
}
