import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/auth/password_reset_storage.dart';
import 'package:hara/features/auth/data/password_reset_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const ticket = PasswordResetTicket(requestId: 'req-1', secret: 'secret-1', email: 'owner@cafe.az');

  Future<AppHarness> openForm(WidgetTester tester, {PasswordResetTicket? saved}) async {
    final app = AppHarness();
    app.resetStorage.saved = saved;
    await app.pump(tester);
    app.router.go('/forgot-password');
    await tester.pumpAndSettle();

    return app;
  }

  Future<void> ask(WidgetTester tester, String email) async {
    await tester.enterText(find.byKey(const Key('resetEmail')), email);
    await tester.tap(find.byKey(const Key('resetSend')));
    await tester.pumpAndSettle();
  }

  /// HARA answers while the owner waits: the screen looks again every few seconds.
  Future<void> waitForNextCheck(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  group('asking', () {
    testWidgets('the sign-in screen has a link for owners who forgot the password', (tester) async {
      final app = AppHarness();
      await app.pump(tester);
      app.router.go('/login');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('forgotPassword')));
      await tester.pumpAndSettle();

      expect(app.currentPath, '/forgot-password');
      expect(find.byKey(const Key('resetEmail')), findsOneWidget);
    });

    testWidgets('a bad email is caught on the phone, nothing is sent', (tester) async {
      final app = await openForm(tester);

      await ask(tester, 'not-an-email');

      expect(app.passwordReset.requested, isEmpty);
      expect(find.byKey(const Key('resetWaiting')), findsNothing);
    });

    testWidgets('a good email sends the request, remembers it and waits', (tester) async {
      final app = await openForm(tester);

      await ask(tester, ' owner@cafe.az ');

      expect(app.passwordReset.requested, ['owner@cafe.az']);
      expect(app.resetStorage.saved?.requestId, 'req-1');
      expect(app.resetStorage.saved?.secret, 'secret-1');
      expect(find.byKey(const Key('resetWaiting')), findsOneWidget);
      expect(find.textContaining('owner@cafe.az'), findsOneWidget);
    });

    testWidgets('if the request cannot be sent the reason shows and nothing is remembered', (tester) async {
      final app = await openForm(tester);
      app.passwordReset.requestError = DioException(requestOptions: RequestOptions(path: '/x'));

      await ask(tester, 'owner@cafe.az');

      expect(find.byKey(const Key('resetError')), findsOneWidget);
      expect(app.resetStorage.saved, isNull);
      expect(find.byKey(const Key('resetWaiting')), findsNothing);
    });
  });

  group('waiting for HARA', () {
    testWidgets('closing the app and coming back picks the request up again', (tester) async {
      final app = await openForm(tester, saved: ticket);

      expect(find.byKey(const Key('resetWaiting')), findsOneWidget);
      expect(app.passwordReset.statusCalls, 1);
      expect(find.byKey(const Key('resetEmail')), findsNothing);
    });

    testWidgets('the screen keeps asking, and shows the form the moment HARA approves', (tester) async {
      final app = await openForm(tester, saved: ticket);
      expect(find.byKey(const Key('resetNewPassword')), findsNothing);

      app.passwordReset.state = PasswordResetState.approved;
      await waitForNextCheck(tester);

      expect(find.byKey(const Key('resetApproved')), findsOneWidget);
      expect(find.byKey(const Key('resetNewPassword')), findsOneWidget);
      expect(find.byKey(const Key('resetRepeatPassword')), findsOneWidget);
    });

    testWidgets('"Check now" asks at once', (tester) async {
      final app = await openForm(tester, saved: ticket);
      final before = app.passwordReset.statusCalls;
      app.passwordReset.state = PasswordResetState.approved;

      await tester.tap(find.byKey(const Key('resetCheck')));
      await tester.pumpAndSettle();

      expect(app.passwordReset.statusCalls, before + 1);
      expect(find.byKey(const Key('resetApproved')), findsOneWidget);
    });

    testWidgets('a failed look-up is quiet while polling and loud when the owner pressed the button', (tester) async {
      final app = await openForm(tester, saved: ticket);
      app.passwordReset.statusError = DioException(requestOptions: RequestOptions(path: '/x'));

      await waitForNextCheck(tester);
      expect(find.byKey(const Key('resetError')), findsNothing);
      expect(find.byKey(const Key('resetWaiting')), findsOneWidget);

      await tester.tap(find.byKey(const Key('resetCheck')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('resetError')), findsOneWidget);
      expect(find.byKey(const Key('resetWaiting')), findsOneWidget);
    });

    testWidgets('cancelling forgets the request and goes back to the start', (tester) async {
      final app = await openForm(tester, saved: ticket);

      await tester.tap(find.byKey(const Key('resetCancel')));
      await tester.pumpAndSettle();

      expect(app.resetStorage.saved, isNull);
      expect(find.byKey(const Key('resetEmail')), findsOneWidget);
    });

    testWidgets('declined: the owner is told, the request is forgotten, and they can ask again', (tester) async {
      final app = await openForm(tester, saved: ticket);
      app.passwordReset.state = PasswordResetState.rejected;

      await waitForNextCheck(tester);

      expect(find.byKey(const Key('resetDeclined')), findsOneWidget);
      expect(app.resetStorage.saved, isNull);

      await tester.tap(find.byKey(const Key('resetAskAgain')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('resetEmail')), findsOneWidget);
    });

    testWidgets('a request that ran out or was used up is dropped, with a note', (tester) async {
      final app = await openForm(tester, saved: ticket);
      app.passwordReset.state = PasswordResetState.expired;

      await waitForNextCheck(tester);

      expect(app.resetStorage.saved, isNull);
      expect(find.byKey(const Key('resetNotice')), findsOneWidget);
      expect(find.byKey(const Key('resetEmail')), findsOneWidget);
    });
  });

  group('choosing the new password', () {
    Future<AppHarness> approved(WidgetTester tester) async {
      final app = await openForm(tester, saved: ticket);
      app.passwordReset.state = PasswordResetState.approved;
      await waitForNextCheck(tester);

      return app;
    }

    Future<void> save(WidgetTester tester, {required String first, required String second}) async {
      await tester.enterText(find.byKey(const Key('resetNewPassword')), first);
      await tester.enterText(find.byKey(const Key('resetRepeatPassword')), second);
      await tester.tap(find.byKey(const Key('resetSave')));
      await tester.pumpAndSettle();
    }

    testWidgets('two different passwords are not sent', (tester) async {
      final app = await approved(tester);

      await save(tester, first: 'Newpass123', second: 'Newpass124');

      expect(find.text("The passwords don't match."), findsOneWidget);
      expect(app.passwordReset.completedWith, isEmpty);
    });

    testWidgets('a password that breaks the rules is not sent', (tester) async {
      final app = await approved(tester);

      await save(tester, first: 'short', second: 'short');

      expect(find.text('At least 8 characters, with a letter and a digit.'), findsOneWidget);
      expect(app.passwordReset.completedWith, isEmpty);
    });

    testWidgets('matching passwords are sent, the request is forgotten and the owner is taken to sign in', (tester) async {
      final app = await approved(tester);

      await save(tester, first: 'Newpass123', second: 'Newpass123');

      expect(app.passwordReset.completedWith, ['Newpass123']);
      expect(app.resetStorage.saved, isNull);
      expect(app.currentPath, '/login');
      expect(find.text('Password changed. Sign in with the new password.'), findsOneWidget);
    });

    testWidgets('if the server refuses the password, the owner can try another and the request stays', (tester) async {
      final app = await approved(tester);
      app.passwordReset.completeError = serverError(400, {
        'errors': {
          'password': ['Passwords must have at least one digit.'],
        },
      });

      await save(tester, first: 'Newpass123', second: 'Newpass123');

      expect(find.byKey(const Key('resetError')), findsOneWidget);
      expect(find.byKey(const Key('resetSave')), findsOneWidget);
      expect(app.resetStorage.saved, isNotNull);
      expect(app.currentPath, '/forgot-password');
    });

    testWidgets('if the request ran out meanwhile, it is dropped with a note and the owner can ask again', (tester) async {
      final app = await approved(tester);
      app.passwordReset.completeError = serverError(400, {
        'errors': {
          'request': ['This reset request is not valid any more. Please ask again.'],
        },
      });

      await save(tester, first: 'Newpass123', second: 'Newpass123');

      expect(app.resetStorage.saved, isNull);
      expect(find.byKey(const Key('resetNotice')), findsOneWidget);
      expect(find.byKey(const Key('resetEmail')), findsOneWidget);
    });
  });
}
