import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/features/legal/privacy_policy.dart';
import 'package:hara/features/venue/data/venue_me.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';
import 'helpers/venue_fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the privacy policy', () {
    test('exists in all three languages with the same sections', () {
      final az = privacyPolicyFor('az');
      final ru = privacyPolicyFor('ru');
      final en = privacyPolicyFor('en');

      expect(az, isNotEmpty);
      expect(ru.length, az.length);
      expect(en.length, az.length);

      for (final language in [az, ru, en]) {
        for (final section in language) {
          expect(section.title.trim(), isNotEmpty);
          expect(section.paragraphs, isNotEmpty);
          expect(section.paragraphs.every((paragraph) => paragraph.trim().isNotEmpty), isTrue);
        }
      }
      for (var i = 0; i < az.length; i++) {
        expect(ru[i].paragraphs.length, az[i].paragraphs.length, reason: 'section $i of ru');
        expect(en[i].paragraphs.length, az[i].paragraphs.length, reason: 'section $i of en');
      }
    });

    test('an unknown language gets the Azerbaijani text', () {
      expect(privacyPolicyFor('de').first.title, privacyPolicyFor('az').first.title);
    });

    test('is dated', () {
      expect(privacyPolicyUpdated, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });

    testWidgets('opens from the welcome screen and shows the text', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness();
      await app.pump(tester);

      await tester.tap(find.byKey(const Key('privacyPolicyLink')));
      await tester.pumpAndSettle();

      expect(app.currentPath, '/privacy');
      expect(find.text('Privacy policy'), findsWidgets);
      expect(find.text('What we collect'), findsOneWidget);
      expect(find.textContaining('We do not sell your data'), findsOneWidget);
    });

    for (final (name, key) in [('sign-in', 'signIn'), ('owner registration', 'registerAsOwner'), ('waiter registration', 'registerAsStaff')]) {
      testWidgets('is linked from the $name screen', (tester) async {
        tester.view.physicalSize = const Size(800, 3200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final app = AppHarness();
        await app.pump(tester);

        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('privacyPolicyLink')));
        await tester.tap(find.byKey(const Key('privacyPolicyLink')));
        await tester.pumpAndSettle();

        expect(app.currentPath, '/privacy');
      });
    }

    testWidgets('is linked from the About us screen', (tester) async {
      final app = AppHarness(continuedAsCustomer: true);
      await app.pump(tester);
      app.router.go('/about');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Privacy policy'));
      await tester.pumpAndSettle();

      expect(app.currentPath, '/privacy');
    });
  });

  group('deleting the account', () {
    Future<(AppHarness, FakeVenueRepository)> open(WidgetTester tester, {VenueMeBuilder? me}) async {
      final venue = FakeVenueRepository(me: (me ?? approvedOwner)());
      final app = AppHarness(session: testSession(), venueRepository: venue);
      await app.pump(tester);

      return (app, venue);
    }

    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('accountMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deleteAccountItem')));
      await tester.pumpAndSettle();
    }

    testWidgets('the menu offers the privacy policy and deleting the account', (tester) async {
      await open(tester);

      await tester.tap(find.byKey(const Key('accountMenu')));
      await tester.pumpAndSettle();

      expect(find.text('Privacy policy'), findsOneWidget);
      expect(find.text('Delete my account'), findsOneWidget);
    });

    testWidgets('it is there for people still waiting for approval, too', (tester) async {
      await open(tester, me: pendingOwner);

      await openDialog(tester);

      expect(find.text('Delete your account?'), findsOneWidget);
    });

    testWidgets('explains what happens and asks for the password', (tester) async {
      await open(tester);

      await openDialog(tester);

      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.textContaining('the restaurant stays listed'), findsOneWidget);
      expect(find.byKey(const Key('deletePassword')), findsOneWidget);
    });

    testWidgets('without a password nothing is sent', (tester) async {
      final (_, venue) = await open(tester);
      await openDialog(tester);

      await tester.tap(find.byKey(const Key('deleteAccountConfirm')));
      await tester.pumpAndSettle();

      expect(venue.deleteAttempts, isEmpty);
      expect(find.text('Delete your account?'), findsOneWidget);
    });

    testWidgets('cancelling deletes nothing', (tester) async {
      final (app, venue) = await open(tester);
      await openDialog(tester);

      await tester.enterText(find.byKey(const Key('deletePassword')), 'Passw0rd1');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(venue.deleteAttempts, isEmpty);
      expect(app.storage.saved, isNotNull, reason: 'still signed in');
      expect(app.currentPath, '/venue');
    });

    testWidgets('a wrong password is explained in the app language and the dialog stays', (tester) async {
      final (app, venue) = await open(tester);
      venue.deleteError = serverFailure(400, {
        'title': 'Validation failed',
        'errors': {
          'password': ['Wrong password.'],
        },
      });
      await openDialog(tester);

      await tester.enterText(find.byKey(const Key('deletePassword')), 'nope12345');
      await tester.tap(find.byKey(const Key('deleteAccountConfirm')));
      await tester.pumpAndSettle();

      expect(venue.deleteAttempts, ['nope12345']);
      expect(tester.widget<Text>(find.byKey(const Key('deleteError'))).data, 'Wrong password.');
      expect(app.storage.saved, isNotNull, reason: 'a failed deletion does not sign anyone out');
    });

    testWidgets('being locked out after too many wrong passwords is explained', (tester) async {
      final (_, venue) = await open(tester);
      venue.deleteError = serverFailure(400, {
        'title': 'Validation failed',
        'errors': {
          'password': ['Too many wrong attempts. Please try again later.'],
        },
      });
      await openDialog(tester);

      await tester.enterText(find.byKey(const Key('deletePassword')), 'Passw0rd1');
      await tester.tap(find.byKey(const Key('deleteAccountConfirm')));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('deleteError'))).data, 'Too many wrong attempts. Please try again later.');
    });

    testWidgets('no connection gets the connection message and keeps the account signed in', (tester) async {
      final (app, venue) = await open(tester);
      venue.deleteError = serverFailure(500).copyWithoutResponse();
      await openDialog(tester);

      await tester.enterText(find.byKey(const Key('deletePassword')), 'Passw0rd1');
      await tester.tap(find.byKey(const Key('deleteAccountConfirm')));
      await tester.pumpAndSettle();

      expect(find.textContaining("Can't reach the server"), findsOneWidget);
      expect(app.storage.saved, isNotNull);
    });

    testWidgets('once deleted this phone forgets the person, says so, and leaves the restaurant screens', (tester) async {
      final (app, venue) = await open(tester);
      await openDialog(tester);

      await tester.enterText(find.byKey(const Key('deletePassword')), 'Passw0rd1');
      await tester.tap(find.byKey(const Key('deleteAccountConfirm')));
      await tester.pumpAndSettle();

      expect(venue.deleteAttempts, ['Passw0rd1']);
      expect(app.storage.saved, isNull, reason: 'the stored session is gone');
      expect(app.auth.logoutCalls, isEmpty, reason: 'the account no longer exists, so there is no session to end on the server');
      expect(find.text('Your account was deleted.'), findsOneWidget);
      expect(app.currentPath, isNot('/venue'));
      expect(app.currentPath, '/welcome');
    });
  });
}

typedef VenueMeBuilder = VenueMe Function();
