import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/auth/auth_repository.dart';
import 'package:hara/features/legal/legal_documents.dart';
import 'package:hara/features/venue/data/venue_me.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';
import 'helpers/venue_fakes.dart';

/// Remembers what the app sent, and answers like a successful sign-up.
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

VenueMe _ownerWith(List<String> pending) => VenueMe(
      isOwner: true,
      status: VenueStatus.approved,
      fullName: 'Anar Aliyev',
      restaurant: approvedOwner().restaurant,
      pendingTerms: pending,
    );

VenueMe _waiterWith(List<String> pending) => VenueMe(
      isOwner: false,
      status: VenueStatus.approved,
      fullName: 'Waiter Wali',
      restaurant: approvedStaff().restaurant,
      pendingTerms: pending,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the texts', () {
    test('both texts exist in all three languages with the same sections, and nothing is empty', () {
      for (final text in LegalText.values) {
        final az = legalTextFor(text, 'az');
        final ru = legalTextFor(text, 'ru');
        final en = legalTextFor(text, 'en');

        expect(az.length, greaterThanOrEqualTo(5), reason: '$text');
        expect(ru.length, az.length, reason: '$text ru');
        expect(en.length, az.length, reason: '$text en');
        for (final section in [...az, ...ru, ...en]) {
          expect(section.title.trim(), isNotEmpty);
          expect(section.paragraphs, isNotEmpty);
          for (final paragraph in section.paragraphs) {
            expect(paragraph.trim(), isNotEmpty);
          }
        }
      }
    });

    test('an unknown language gets the Azerbaijani text, like the privacy policy', () {
      expect(legalTextFor(LegalText.terms, 'tr').first.title, legalTextFor(LegalText.terms, 'az').first.title);
      expect(legalTextFor(LegalText.terms, 'en').first.title, 'What HARA is');
    });

    test('the versions are real numbers and the date is a date', () {
      expect(termsVersion, greaterThanOrEqualTo(1));
      expect(venueAgreementVersion, greaterThanOrEqualTo(1));
      expect(DateTime.tryParse(legalTextsUpdated), isNotNull);
    });
  });

  group('reading them', () {
    testWidgets('the terms of use open from the welcome screen', (tester) async {
      final app = AppHarness();
      await app.pump(tester);

      await tester.scrollUntilVisible(find.byKey(const Key('termsLink')), 200);
      await tester.tap(find.byKey(const Key('termsLink')));
      await tester.pumpAndSettle();

      expect(app.currentPath, '/terms');
      expect(find.text('Terms of use'), findsOneWidget);
      expect(find.text('What HARA is'), findsOneWidget);
      expect(find.text(legalTextsUpdated), findsOneWidget);
    });

    testWidgets('the terms and the restaurant agreement are both in "About"', (tester) async {
      final app = AppHarness(continuedAsCustomer: true);
      await app.pump(tester);
      app.router.go('/about');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('aboutAgreement')));
      await tester.pumpAndSettle();

      expect(app.currentPath, '/restaurant-agreement');
      expect(find.text('Restaurant agreement'), findsOneWidget);
      expect(find.text('What the restaurant promises'), findsOneWidget);

      app.router.go('/about');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('aboutTerms')));
      await tester.pumpAndSettle();

      expect(app.currentPath, '/terms');
    });

    testWidgets('the sign-up screens link to what is being accepted', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness();
      await app.pump(tester);
      app.router.go('/register-owner');
      await tester.pumpAndSettle();

      final agreementBox = find.byKey(const Key('acceptAgreement'));
      await tester.tap(find.descendant(of: agreementBox, matching: find.text('Restaurant agreement')));
      await tester.pumpAndSettle();

      expect(app.currentPath, '/restaurant-agreement');
    });
  });

  group('what the server is told at sign-up', () {
    Future<Map<String, dynamic>> sent(Future<void> Function(AuthRepository) signUp) async {
      final adapter = _CaptureAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))..httpClientAdapter = adapter;
      await signUp(AuthRepository(dio));

      return adapter.requests.single.data as Map<String, dynamic>;
    }

    test('an owner sends the version of both texts', () async {
      final body = await sent((repository) => repository.registerOwner(
            email: 'a@b.az',
            password: 'Passw0rd1',
            fullName: 'A',
            restaurantName: 'R',
            address: 'Baku',
          ));

      expect(body['acceptedTermsVersion'], termsVersion);
      expect(body['acceptedVenueAgreementVersion'], venueAgreementVersion);
    });

    test('a waiter sends the version of the terms of use', () async {
      final body = await sent((repository) => repository.registerStaff(
            email: 'a@b.az',
            password: 'Passw0rd1',
            fullName: 'A',
            restaurantId: 'r1',
          ));

      expect(body['acceptedTermsVersion'], termsVersion);
      expect(body.containsKey('acceptedVenueAgreementVersion'), isFalse);
    });
  });

  group('new or changed texts', () {
    Future<(AppHarness, FakeVenueRepository)> openAs(WidgetTester tester, VenueMe me) async {
      final venue = FakeVenueRepository(me: me);
      final app = AppHarness(session: testSession(roles: [me.isOwner ? 'Owner' : 'Staff']), venueRepository: venue);
      await app.pump(tester);

      return (app, venue);
    }

    testWidgets('an owner who has not accepted sees only the two texts, not the working screens', (tester) async {
      await openAs(tester, _ownerWith(['terms', 'venueAgreement']));

      expect(find.text('Please accept the terms'), findsOneWidget);
      expect(find.byKey(const Key('gate-terms')), findsOneWidget);
      expect(find.byKey(const Key('gate-venueAgreement')), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Requests'), findsNothing);
      expect(find.text('Cafe One'), findsNothing);
    });

    testWidgets('a waiter is asked only for the terms of use', (tester) async {
      await openAs(tester, _waiterWith(['terms']));

      expect(find.byKey(const Key('gate-terms')), findsOneWidget);
      expect(find.byKey(const Key('gate-venueAgreement')), findsNothing);
    });

    testWidgets('only the text that changed is asked again', (tester) async {
      await openAs(tester, _ownerWith(['venueAgreement']));

      expect(find.byKey(const Key('gate-terms')), findsNothing);
      expect(find.byKey(const Key('gate-venueAgreement')), findsOneWidget);
    });

    testWidgets('"Accept" stays off until every box is ticked', (tester) async {
      final (_, venue) = await openAs(tester, _ownerWith(['terms', 'venueAgreement']));
      FilledButton accept() => tester.widget<FilledButton>(find.byKey(const Key('gateAccept')));

      expect(accept().onPressed, isNull);
      await tester.tap(find.byKey(const Key('gate-terms')));
      await tester.pump();
      expect(accept().onPressed, isNull);
      await tester.tap(find.byKey(const Key('gate-venueAgreement')));
      await tester.pump();
      expect(accept().onPressed, isNotNull);
      expect(venue.acceptedTerms, isEmpty);
    });

    testWidgets('accepting sends the current versions and opens the working screens', (tester) async {
      final (_, venue) = await openAs(tester, _ownerWith(['terms', 'venueAgreement']));

      await tester.tap(find.byKey(const Key('gate-terms')));
      await tester.tap(find.byKey(const Key('gate-venueAgreement')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('gateAccept')));
      await tester.pumpAndSettle();

      expect(venue.acceptedTerms, [(terms: termsVersion, agreement: venueAgreementVersion)]);
      expect(find.text('Please accept the terms'), findsNothing);
      expect(find.widgetWithText(Tab, 'Requests'), findsOneWidget);
    });

    testWidgets('a waiter sends only the terms version, and the agreement\'s stays 0', (tester) async {
      final (_, venue) = await openAs(tester, _waiterWith(['terms']));

      await tester.tap(find.byKey(const Key('gate-terms')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('gateAccept')));
      await tester.pumpAndSettle();

      expect(venue.acceptedTerms, [(terms: termsVersion, agreement: 0)]);
    });

    testWidgets('the texts can be read from the gate', (tester) async {
      final (app, _) = await openAs(tester, _ownerWith(['terms', 'venueAgreement']));

      await tester.tap(find.byKey(const Key('gate-read-venueAgreement')));
      await tester.pumpAndSettle();

      expect(app.currentPath, '/restaurant-agreement');
      expect(find.text('What the restaurant promises'), findsOneWidget);
    });

    testWidgets('if the server refuses, the reason shows and the gate stays', (tester) async {
      final (_, venue) = await openAs(tester, _ownerWith(['terms', 'venueAgreement']));
      venue.acceptError = serverFailure(400, {
        'errors': {
          'termsVersion': ['Please accept the current version of this text.'],
        },
      });

      await tester.tap(find.byKey(const Key('gate-terms')));
      await tester.tap(find.byKey(const Key('gate-venueAgreement')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('gateAccept')));
      await tester.pumpAndSettle();

      expect(find.text('Please accept the current version of this text.'), findsOneWidget);
      expect(find.byKey(const Key('gateAccept')), findsOneWidget);
    });

    testWidgets('an account with everything accepted never sees the gate', (tester) async {
      await openAs(tester, approvedOwner());

      expect(find.text('Please accept the terms'), findsNothing);
      expect(find.widgetWithText(Tab, 'Requests'), findsOneWidget);
    });
  });

  test('the server answer carries what is pending', () {
    final me = VenueMe.fromJson({
      'role': 'Owner',
      'status': 'Approved',
      'pendingTerms': ['terms', 'venueAgreement'],
    });
    final older = VenueMe.fromJson({'role': 'Owner', 'status': 'Approved'});

    expect(me.pendingTerms, ['terms', 'venueAgreement']);
    expect(older.pendingTerms, isEmpty);
  });
}
