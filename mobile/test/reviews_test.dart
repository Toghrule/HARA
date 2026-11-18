import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/features/reviews/data/review.dart';

import 'helpers/app_harness.dart';

Review review(int n, {int stars = 4, String? text}) => Review(
      id: 'r$n',
      stars: stars,
      text: text ?? 'Review number $n',
      createdAt: DateTime(2026, 10, n),
      authorName: 'Person $n',
    );

Future<void> openMore(WidgetTester tester) async {
  await tester.tap(find.text('More'));
  await tester.pumpAndSettle();
}

/// More tab → My account.
Future<void> openAccount(WidgetTester tester) async {
  await openMore(tester);
  await tester.tap(find.byKey(const Key('aboutAccount')));
  await tester.pumpAndSettle();
}

Future<void> openCafe(WidgetTester tester, AppHarness app) async {
  await app.pump(tester);
  await tester.tap(find.text('Cafe One'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('account card in the More tab', () {
    testWidgets('offers Google sign-in; signing in shows the name', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(googleAvailable: true, continuedAsCustomer: true);
      await app.pump(tester);
      await openAccount(tester);

      await tester.ensureVisible(find.byKey(const Key('signInWithGoogle')));
      await tester.tap(find.byKey(const Key('signInWithGoogle')));
      await tester.pumpAndSettle();

      expect(app.customerServer.idTokens, ['google-token']);
      expect(find.byKey(const Key('customerName')), findsOneWidget);
      expect(find.text('Anna K.'), findsOneWidget);
      expect(app.customerStorage.saved, isNotNull);
    });

    testWidgets('closing the Google window changes nothing', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(googleAvailable: true, continuedAsCustomer: true);
      app.google.token = null;
      await app.pump(tester);
      await openAccount(tester);

      await tester.tap(find.byKey(const Key('signInWithGoogle')));
      await tester.pumpAndSettle();

      expect(app.customerServer.idTokens, isEmpty);
      expect(find.byKey(const Key('signInWithGoogle')), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a failed sign-in says so', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(googleAvailable: true, continuedAsCustomer: true);
      app.google.error = Exception('no network');
      await app.pump(tester);
      await openAccount(tester);

      await tester.tap(find.byKey(const Key('signInWithGoogle')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not sign in. Please try again in a moment.'), findsOneWidget);
      expect(find.textContaining('_Exception'), findsOneWidget);
    });

    testWidgets('nothing is offered where Google is not available', (tester) async {
      final app = AppHarness(continuedAsCustomer: true);
      await app.pump(tester);
      await openMore(tester);

      expect(find.byKey(const Key('aboutAccount')), findsNothing);
    });

    testWidgets('signed out, the account page links the documents and the restaurant sign-in', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(googleAvailable: true, continuedAsCustomer: true);
      await app.pump(tester);
      await openAccount(tester);

      expect(find.byKey(const Key('accountConsent')), findsOneWidget);
      expect(find.text('Reviews'), findsOneWidget);

      await tester.tap(find.byKey(const Key('restaurantLogin')));
      await tester.pumpAndSettle();
      expect(app.currentPath, '/login');
    });

    testWidgets('signing out forgets the customer', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(googleAvailable: true, continuedAsCustomer: true, customer: testCustomer());
      await app.pump(tester);
      await openAccount(tester);

      await tester.tap(find.byKey(const Key('customerSignOut')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('signInWithGoogle')), findsOneWidget);
      expect(app.google.signOuts, 1);
      expect(app.customerStorage.saved, isNull);
    });

    testWidgets('deleting the account asks first, then deletes', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(googleAvailable: true, continuedAsCustomer: true, customer: testCustomer());
      await app.pump(tester);
      await openAccount(tester);

      await tester.tap(find.byKey(const Key('customerDelete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(app.customerServer.deletes, 0);

      await tester.tap(find.byKey(const Key('customerDelete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('customerDeleteConfirm')));
      await tester.pumpAndSettle();

      expect(app.customerServer.deletes, 1);
      expect(find.byKey(const Key('signInWithGoogle')), findsOneWidget);
      expect(app.customerStorage.saved, isNull);
    });
  });

  group('reviews on the restaurant page', () {
    testWidgets('shows the reviews with short names', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(continuedAsCustomer: true, reviews: [review(2), review(1)]);
      await openCafe(tester, app);

      expect(find.text('Review number 2'), findsOneWidget);
      expect(find.text('Person 1'), findsOneWidget);
      expect(find.byKey(const Key('writeReview')), findsNothing);
    });

    testWidgets('says so when there are none', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(continuedAsCustomer: true);
      await openCafe(tester, app);

      expect(find.byKey(const Key('noReviews')), findsOneWidget);
    });

    testWidgets('"show more" loads the next page', (tester) async {
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(continuedAsCustomer: true, reviews: [for (var i = 12; i >= 1; i--) review(i)]);
      await openCafe(tester, app);

      expect(find.byType(ListTile, skipOffstage: false).evaluate().where((e) => (e.widget as ListTile).key.toString().contains('review-')).length, 10);
      await tester.ensureVisible(find.byKey(const Key('reviewsShowMore')));
      await tester.tap(find.byKey(const Key('reviewsShowMore')));
      await tester.pumpAndSettle();

      expect(app.reviewsServer.pagesAsked, [1, 2]);
      expect(find.byKey(const Key('review-r1')), findsOneWidget);
      expect(find.byKey(const Key('reviewsShowMore')), findsNothing);
    });

    testWidgets('writing a review signs in first, then saves the stars and the words', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(continuedAsCustomer: true, googleAvailable: true);
      await openCafe(tester, app);

      await tester.ensureVisible(find.byKey(const Key('writeReview')));
      await tester.tap(find.byKey(const Key('writeReview')));
      await tester.pumpAndSettle();
      expect(app.google.signIns, 1);

      await tester.tap(find.byKey(const Key('star4')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('reviewText')), '  Lovely  ');
      await tester.tap(find.byKey(const Key('saveReview')));
      await tester.pumpAndSettle();

      expect(app.reviewsServer.saved, [(restaurantId: 'rest-1', stars: 4, text: 'Lovely')]);
      expect(find.text('Your review was saved'), findsOneWidget);
      expect(find.byKey(const Key('saveReview')), findsNothing);
      expect(find.text('Change my review'), findsOneWidget);
    });

    testWidgets('closing the Google window opens nothing', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(continuedAsCustomer: true, googleAvailable: true);
      app.google.token = null;
      await openCafe(tester, app);

      await tester.ensureVisible(find.byKey(const Key('writeReview')));
      await tester.tap(find.byKey(const Key('writeReview')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('saveReview')), findsNothing);
    });

    testWidgets('stars are required', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(continuedAsCustomer: true, googleAvailable: true, customer: testCustomer());
      await openCafe(tester, app);

      await tester.ensureVisible(find.byKey(const Key('writeReview')));
      await tester.tap(find.byKey(const Key('writeReview')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('saveReview')));
      await tester.pump();

      expect(find.byKey(const Key('starsRequired')), findsOneWidget);
      expect(app.reviewsServer.saved, isEmpty);
    });

    testWidgets('an existing review is shown for changing, and can be removed', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(continuedAsCustomer: true, googleAvailable: true, customer: testCustomer());
      app.reviewsServer.mine = review(5, stars: 2, text: 'Meh');
      await openCafe(tester, app);

      expect(find.text('Change my review'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('writeReview')));
      await tester.tap(find.byKey(const Key('writeReview')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Meh'), findsOneWidget);

      await tester.tap(find.byKey(const Key('deleteReview')));
      await tester.pumpAndSettle();

      expect(app.reviewsServer.deleted, ['rest-1']);
      expect(find.text('Your review was removed'), findsOneWidget);
      expect(find.text('Write a review'), findsOneWidget);
    });
  });
}
