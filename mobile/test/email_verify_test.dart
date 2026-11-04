import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/auth/auth_repository.dart';
import 'package:hara/features/venue/data/venue_me.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';
import 'helpers/venue_fakes.dart';

class _CaptureAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);

    return ResponseBody.fromString(
      '{"token":"t","expiresAtUtc":"2030-01-01T00:00:00Z","refreshToken":"r","roles":["Owner"]}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

VenueMe _unconfirmed() => VenueMe(
      isOwner: true,
      status: VenueStatus.approved,
      fullName: 'Anar Aliyev',
      restaurant: approvedOwner().restaurant,
      pendingTerms: const ['terms', 'venueAgreement'],
      emailToVerify: 'anar@cafe.az',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the language of the email travels with the sign-up', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))..httpClientAdapter = adapter;
    await AuthRepository(dio).registerOwner(email: 'a@b.az', password: 'Passw0rd1', fullName: 'A', restaurantName: 'R', address: 'Baku', language: 'ru');
    await AuthRepository(dio).registerStaff(email: 'a@b.az', password: 'Passw0rd1', fullName: 'A', restaurantId: 'r1', language: 'en');

    expect((adapter.requests[0].data as Map)['language'], 'ru');
    expect((adapter.requests[1].data as Map)['language'], 'en');
  });

  test('the address to confirm is read from who the person is', () {
    expect(VenueMe.fromJson({'role': 'Owner', 'status': 'Approved', 'emailToVerify': 'a@b.az'}).emailToVerify, 'a@b.az');
    expect(VenueMe.fromJson({'role': 'Owner', 'status': 'Approved'}).emailToVerify, isNull);
  });

  group('the confirmation screen', () {
    Future<(AppHarness, FakeVenueRepository)> open(WidgetTester tester) async {
      final venue = FakeVenueRepository(me: _unconfirmed());
      final app = AppHarness(session: testSession(roles: ['Owner']), venueRepository: venue);
      await app.pump(tester);

      return (app, venue);
    }

    testWidgets('comes before the terms and the working screens', (tester) async {
      await open(tester);

      expect(find.text('Confirm your email'), findsWidgets);
      expect(find.textContaining('anar@cafe.az'), findsOneWidget);
      expect(find.text('Please accept the terms'), findsNothing);
      expect(find.widgetWithText(Tab, 'Requests'), findsNothing);
    });

    testWidgets('a code that is not six digits is not even sent', (tester) async {
      final (_, venue) = await open(tester);

      await tester.enterText(find.byKey(const Key('emailCode')), '123');
      await tester.tap(find.byKey(const Key('verifyConfirm')));
      await tester.pump();

      expect(venue.typedCodes, isEmpty);
      expect(find.text('The code is six digits.'), findsOneWidget);
    });

    testWidgets('a wrong code shows the reason and stays', (tester) async {
      final (_, venue) = await open(tester);

      await tester.enterText(find.byKey(const Key('emailCode')), '000000');
      await tester.tap(find.byKey(const Key('verifyConfirm')));
      await tester.pumpAndSettle();

      expect(venue.typedCodes, ['000000']);
      expect(find.text('That code is not right.'), findsOneWidget);
      expect(find.text('Confirm your email'), findsWidgets);
    });

    testWidgets('the right code moves on to the next step', (tester) async {
      final (_, venue) = await open(tester);

      await tester.enterText(find.byKey(const Key('emailCode')), '123456');
      await tester.tap(find.byKey(const Key('verifyConfirm')));
      await tester.pumpAndSettle();

      expect(venue.typedCodes, ['123456']);
      expect(find.byKey(const Key('emailCode')), findsNothing);
      expect(find.widgetWithText(Tab, 'Requests'), findsOneWidget);
    });

    testWidgets('asking for a new code waits a minute, then sends in the app\'s language', (tester) async {
      final (_, venue) = await open(tester);
      TextButton resend() => tester.widget<TextButton>(find.byKey(const Key('verifyResend')));

      expect(resend().onPressed, isNull);
      expect(find.textContaining('Send again in'), findsOneWidget);

      await tester.pump(const Duration(seconds: 61));
      expect(resend().onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('verifyResend')));
      await tester.pump();

      expect(venue.resends, ['en']);
      expect(find.text('A new code is on its way.'), findsOneWidget);
      expect(resend().onPressed, isNull);
    });

    testWidgets('the server\'s "wait" and "too many" answers are shown in the app\'s language', (tester) async {
      final (_, venue) = await open(tester);
      venue.verifyError = serverFailure(400, {'errors': {'code': ['Too many wrong tries. Ask for a new code.']}});

      await tester.enterText(find.byKey(const Key('emailCode')), '111111');
      await tester.tap(find.byKey(const Key('verifyConfirm')));
      await tester.pumpAndSettle();

      expect(find.text('Too many wrong tries. Ask for a new code.'), findsOneWidget);
    });
  });
}
