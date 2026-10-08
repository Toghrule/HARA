import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/auth/auth_controller.dart';
import 'package:hara/features/auth/data/customer_choice.dart';
import 'package:hara/features/venue/data/venue_me.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';
import 'helpers/venue_fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('where the app opens', () {
    testWidgets('first launch asks whether this is a customer or a restaurant person', (tester) async {
      final app = AppHarness();
      await app.pump(tester);

      expect(app.currentPath, '/welcome');
      expect(find.text('Welcome to HARA'), findsOneWidget);
      expect(find.text('Continue as a customer'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Register as a restaurant owner'), findsOneWidget);
      expect(find.text('Register as a waiter'), findsOneWidget);
    });

    testWidgets('after choosing "Continue as a customer" the restaurants open, now and next time', (tester) async {
      final app = AppHarness();
      await app.pump(tester);

      await tester.tap(find.byKey(const Key('continueAsCustomer')));
      await tester.pumpAndSettle();

      expect(app.currentPath, '/');
      expect(find.text('Cafe One'), findsOneWidget);
      expect((await SharedPreferences.getInstance()).getBool('continued_as_customer'), isTrue);
      expect(await loadContinuedAsCustomer(), isTrue);
    });

    testWidgets('someone who already chose customer goes straight to the restaurants', (tester) async {
      final app = AppHarness(continuedAsCustomer: true);
      await app.pump(tester);

      expect(app.currentPath, '/');
      expect(find.text('Cafe One'), findsOneWidget);
    });

    testWidgets('a signed-in owner opens straight to their restaurant', (tester) async {
      final app = AppHarness(session: testSession(), venueRepository: FakeVenueRepository(me: approvedOwner()));
      await app.pump(tester);

      expect(app.currentPath, '/venue');
    });

    testWidgets('the account button leads a customer to the welcome screen and an owner to their restaurant', (tester) async {
      final guest = AppHarness(continuedAsCustomer: true);
      await guest.pump(tester);
      await tester.tap(find.byKey(const Key('accountButton')));
      await tester.pumpAndSettle();
      expect(guest.currentPath, '/welcome');
    });

    testWidgets('restaurant screens are closed to people who are not signed in', (tester) async {
      final app = AppHarness(continuedAsCustomer: true);
      await app.pump(tester);

      app.router.go('/venue');
      await tester.pumpAndSettle();

      expect(app.currentPath, '/welcome');
    });

    testWidgets('a signed-in person is kept off the sign-in and sign-up screens', (tester) async {
      final app = AppHarness(session: testSession(), venueRepository: FakeVenueRepository(me: approvedOwner()));
      await app.pump(tester);

      for (final path in ['/login', '/welcome', '/register-owner', '/register-staff']) {
        app.router.go(path);
        await tester.pumpAndSettle();
        expect(app.currentPath, '/venue', reason: path);
      }
    });
  });

  group('signing in', () {
    Future<AppHarness> openLogin(WidgetTester tester, {FakeVenueRepository? venue}) async {
      final app = AppHarness(venueRepository: venue ?? FakeVenueRepository(me: approvedOwner()));
      await app.pump(tester);
      await tester.tap(find.byKey(const Key('signIn')));
      await tester.pumpAndSettle();

      return app;
    }

    testWidgets('empty fields are caught before anything is sent', (tester) async {
      final app = await openLogin(tester);

      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsNWidgets(2));
      expect(app.auth.calls, isEmpty);
    });

    testWidgets('signing in opens the restaurant and keeps the session on the device', (tester) async {
      final app = await openLogin(tester);

      await tester.enterText(find.byKey(const Key('email')), ' owner@cafe.az ');
      await tester.enterText(find.byKey(const Key('password')), 'Passw0rd1');
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();

      expect(app.auth.calls.single, {'call': 'login', 'email': 'owner@cafe.az', 'password': 'Passw0rd1'});
      expect(app.currentPath, '/venue');
      expect(app.storage.saved, isNotNull);
    });

    testWidgets('a wrong password says so and stays on the screen', (tester) async {
      final app = await openLogin(tester);
      app.auth.error = serverError(401, {'title': 'Invalid email or password.', 'status': 401});

      await tester.enterText(find.byKey(const Key('email')), 'owner@cafe.az');
      await tester.enterText(find.byKey(const Key('password')), 'nope');
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();

      expect(find.text('Wrong email or password.'), findsOneWidget);
      expect(app.currentPath, '/login');
      expect(app.storage.saved, isNull);
    });

    testWidgets('no connection gets the connection message, not "wrong password"', (tester) async {
      final app = await openLogin(tester);
      app.auth.error = serverError(0).copyWithoutResponse();

      await tester.enterText(find.byKey(const Key('email')), 'owner@cafe.az');
      await tester.enterText(find.byKey(const Key('password')), 'Passw0rd1');
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();

      expect(find.textContaining("Can't reach the server"), findsOneWidget);
      expect(find.text('Wrong email or password.'), findsNothing);
    });

    testWidgets('too many attempts is explained', (tester) async {
      final app = await openLogin(tester);
      app.auth.error = serverError(429, {'title': 'Too many attempts. Please try again later.', 'status': 429});

      await tester.enterText(find.byKey(const Key('email')), 'owner@cafe.az');
      await tester.enterText(find.byKey(const Key('password')), 'x');
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();

      expect(find.text('Too many attempts. Please try again later.'), findsOneWidget);
    });
  });

  group('registering as an owner', () {
    Future<AppHarness> openForm(WidgetTester tester) async {
      // A tall screen, so the whole long form is on it and every error message can be found.
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final app = AppHarness(venueRepository: FakeVenueRepository(me: pendingOwner()));
      await app.pump(tester);
      await tester.tap(find.byKey(const Key('registerAsOwner')));
      await tester.pumpAndSettle();

      return app;
    }

    Future<void> fill(
      WidgetTester tester, {
      String password = 'Passw0rd1',
      String confirm = 'Passw0rd1',
      String email = 'owner@cafe.az',
    }) async {
      Future<void> type(String key, String value) async {
        await tester.ensureVisible(find.byKey(Key(key)));
        await tester.enterText(find.byKey(Key(key)), value);
      }

      await type('fullName', ' Anar Aliyev ');
      await type('email', email);
      await type('password', password);
      await type('confirmPassword', confirm);
      await type('restaurantName', 'Cafe One');
      await type('address', 'Baku, Nizami 1');
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('submit')));
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();
    }

    testWidgets('sends the account and the restaurant, then shows "waiting for approval"', (tester) async {
      final app = await openForm(tester);

      await fill(tester);
      await submit(tester);

      expect(app.auth.calls.single, {
        'call': 'registerOwner',
        'email': 'owner@cafe.az',
        'password': 'Passw0rd1',
        'fullName': 'Anar Aliyev',
        'phoneNumber': null,
        'restaurantName': 'Cafe One',
        'address': 'Baku, Nizami 1',
        'restaurantPhoneNumber': null,
        'description': null,
      });
      expect(app.currentPath, '/venue');
      expect(find.text('Waiting for approval'), findsOneWidget);
    });

    testWidgets('a weak password is explained before anything is sent', (tester) async {
      final app = await openForm(tester);

      await fill(tester, password: 'short1', confirm: 'short1');
      await submit(tester);

      expect(find.text('At least 8 characters, with a letter and a digit.'), findsOneWidget);
      expect(app.auth.calls, isEmpty);
    });

    testWidgets('a password with no digit is refused', (tester) async {
      final app = await openForm(tester);

      await fill(tester, password: 'onlyletters', confirm: 'onlyletters');
      await submit(tester);

      expect(find.text('At least 8 characters, with a letter and a digit.'), findsOneWidget);
      expect(app.auth.calls, isEmpty);
    });

    testWidgets('two different passwords are caught', (tester) async {
      final app = await openForm(tester);

      await fill(tester, confirm: 'Passw0rd2');
      await submit(tester);

      expect(find.text("The passwords don't match."), findsOneWidget);
      expect(app.auth.calls, isEmpty);
    });

    testWidgets('a bad email is caught', (tester) async {
      final app = await openForm(tester);

      await fill(tester, email: 'not-an-email');
      await submit(tester);

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(app.auth.calls, isEmpty);
    });

    testWidgets('an email that is already registered is explained in the app language', (tester) async {
      final app = await openForm(tester);
      app.auth.error = serverError(400, {
        'title': 'Validation failed',
        'errors': {
          'email': ["Email 'owner@cafe.az' is already taken."],
        },
      });

      await fill(tester);
      await submit(tester);

      expect(find.text('This email is already registered.'), findsOneWidget);
      expect(app.currentPath, '/register-owner');
      expect(app.storage.saved, isNull);
    });

    testWidgets('the password box has an eye button', (tester) async {
      await openForm(tester);

      final field = find.descendant(of: find.byKey(const Key('password')), matching: find.byType(EditableText));
      expect(tester.widget<EditableText>(field).obscureText, isTrue);

      await tester.ensureVisible(find.byTooltip('Show password').first);
      await tester.tap(find.byTooltip('Show password').first);
      await tester.pump();

      expect(tester.widget<EditableText>(field).obscureText, isFalse);
    });
  });

  group('registering as a waiter', () {
    Future<AppHarness> openForm(WidgetTester tester) async {
      // A tall screen, so the whole long form is on it and every error message can be found.
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final app = AppHarness(venueRepository: FakeVenueRepository(me: pendingStaff()));
      await app.pump(tester);
      await tester.tap(find.byKey(const Key('registerAsStaff')));
      await tester.pumpAndSettle();

      return app;
    }

    Future<void> fillAccount(WidgetTester tester) async {
      Future<void> type(String key, String value) async {
        await tester.ensureVisible(find.byKey(Key(key)));
        await tester.enterText(find.byKey(Key(key)), value);
      }

      await type('fullName', 'Waiter Wali');
      await type('email', 'wali@cafe.az');
      await type('password', 'Passw0rd1');
      await type('confirmPassword', 'Passw0rd1');
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('submit')));
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();
    }

    testWidgets('lists restaurants to pick from and narrows them as you type', (tester) async {
      await openForm(tester);

      expect(find.text('Cafe One'), findsOneWidget);
      expect(find.text('Bistro Two'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('restaurantSearch')), 'bistro');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Cafe One'), findsNothing);
      expect(find.text('Bistro Two'), findsOneWidget);
    });

    testWidgets('picking the restaurant is required', (tester) async {
      final app = await openForm(tester);

      await fillAccount(tester);
      await submit(tester);

      expect(find.text('Pick your restaurant first.'), findsOneWidget);
      expect(app.auth.calls, isEmpty);
    });

    testWidgets('sends the chosen restaurant and shows "waiting for the owner"', (tester) async {
      final app = await openForm(tester);

      await tester.tap(find.text('Bistro Two'));
      await tester.pump();
      await fillAccount(tester);
      await submit(tester);

      expect(app.auth.calls.single['call'], 'registerStaff');
      expect(app.auth.calls.single['restaurantId'], 'rest-2');
      expect(app.auth.calls.single['fullName'], 'Waiter Wali');
      expect(app.currentPath, '/venue');
      expect(find.textContaining('owner has to approve you'), findsOneWidget);
    });
  });

  group('the restaurant home', () {
    Future<AppHarness> openVenue(WidgetTester tester, VenueMe me) async {
      final app = AppHarness(session: testSession(), venueRepository: FakeVenueRepository(me: me));
      await app.pump(tester);

      return app;
    }

    testWidgets('an owner waiting for approval is told so', (tester) async {
      await openVenue(tester, pendingOwner());

      expect(find.text('Waiting for approval'), findsOneWidget);
      expect(find.textContaining('reviewing your registration'), findsOneWidget);
    });

    testWidgets('a declined owner sees the reason', (tester) async {
      await openVenue(tester, rejectedOwner(note: 'Address not found'));

      expect(find.text('Not approved'), findsOneWidget);
      expect(find.textContaining('Reason: Address not found'), findsOneWidget);
    });

    testWidgets('an account with nothing on record says it is not linked', (tester) async {
      await openVenue(tester, noVenue());

      expect(find.text('This account is not linked to a restaurant.'), findsOneWidget);
    });

    testWidgets('"Check again" asks the server again', (tester) async {
      final venue = FakeVenueRepository(me: pendingOwner());
      final app = AppHarness(session: testSession(), venueRepository: venue);
      await app.pump(tester);
      expect(venue.meCalls, 1);

      venue.me = approvedOwner();
      await tester.tap(find.text('Check again'));
      await tester.pumpAndSettle();

      expect(venue.meCalls, 2);
      expect(find.text('Waiting for approval'), findsNothing);
    });

    testWidgets('signing out ends the session and goes back to the welcome screen', (tester) async {
      final app = await openVenue(tester, pendingOwner());

      await tester.tap(find.byTooltip('Sign out'));
      await tester.pumpAndSettle();

      expect(app.auth.logoutCalls, ['refresh-1']);
      expect(app.storage.saved, isNull);
      expect(app.container.read(authControllerProvider), isNull);
      expect(app.currentPath, '/welcome');
    });
  });
}
