import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/features/reservations/data/reservation_state.dart';
import 'package:hara/features/venue/data/venue_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';
import 'helpers/venue_fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(AppHarness, FakeVenueRepository)> open(WidgetTester tester, {bool owner = false}) async {
    final venue = FakeVenueRepository(me: owner ? approvedOwner() : approvedStaff());
    final app = AppHarness(session: testSession(roles: [owner ? 'Owner' : 'Staff']), venueRepository: venue);
    await app.pump(tester);

    return (app, venue);
  }

  Future<void> goToTab(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(Tab, label));
    await tester.pumpAndSettle();
  }

  group('the tabs', () {
    testWidgets('a waiter can confirm codes and see reservations, nothing else', (tester) async {
      await open(tester);

      expect(find.text('Cafe One'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Confirm code'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Reservations'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Team'), findsNothing);
      expect(find.widgetWithText(Tab, 'Restaurant'), findsNothing);
    });

    testWidgets('the owner also gets the team and the restaurant', (tester) async {
      await open(tester, owner: true);

      expect(find.widgetWithText(Tab, 'Team'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Restaurant'), findsOneWidget);
    });
  });

  group('confirming a code', () {
    Future<void> checkCode(WidgetTester tester, String typed) async {
      await tester.enterText(find.byKey(const Key('codeInput')), typed);
      await tester.tap(find.byKey(const Key('checkCode')));
      await tester.pumpAndSettle();
    }

    testWidgets('looks the code up (any case, stray spaces ignored) and shows what to do', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['AB12CD'] = reservationOf('AB12CD', discountPercent: 15, phone: '+994509998877');

      await checkCode(tester, ' ab12 cd ');

      expect(venue.lookups, ['AB12CD']);
      expect(find.text('AB12CD'), findsWidgets);
      expect(tester.widget<Text>(find.byKey(const Key('detailStatus'))).data, 'Valid');
      expect(find.text('Give 15% off the bill.'), findsOneWidget);
      expect(find.text("Customer's phone: +994509998877"), findsOneWidget);
      expect(find.textContaining('Valid until'), findsOneWidget);
      expect(find.byKey(const Key('confirmCode')), findsOneWidget);
    });

    testWidgets('a restaurant without a discount says so', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['ZERO11'] = reservationOf('ZERO11', discountPercent: 0);

      await checkCode(tester, 'zero11');

      expect(find.text('This restaurant has no discount.'), findsOneWidget);
    });

    testWidgets('confirming asks first, then marks the code used', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['AB12CD'] = reservationOf('AB12CD');
      await checkCode(tester, 'ab12cd');

      await tester.tap(find.byKey(const Key('confirmCode')));
      await tester.pumpAndSettle();
      expect(find.text('Confirm this code?'), findsOneWidget);
      expect(venue.redeemed, isEmpty, reason: 'nothing happens before the waiter agrees');

      await tester.tap(find.byKey(const Key('confirmDialogYes')));
      await tester.pumpAndSettle();

      expect(venue.redeemed, ['AB12CD']);
      expect(tester.widget<Text>(find.byKey(const Key('detailStatus'))).data, 'Code confirmed');
      expect(find.text("Apply the discount to the customer's bill."), findsOneWidget);
      expect(find.byKey(const Key('confirmCode')), findsNothing, reason: 'a code can only be confirmed once');
    });

    testWidgets('backing out of the question confirms nothing', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['AB12CD'] = reservationOf('AB12CD');
      await checkCode(tester, 'ab12cd');

      await tester.tap(find.byKey(const Key('confirmCode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(venue.redeemed, isEmpty);
      expect(find.byKey(const Key('confirmCode')), findsOneWidget);
    });

    testWidgets('a code of another restaurant (or a made-up one) is simply not found', (tester) async {
      await open(tester);

      await checkCode(tester, 'nosuch');

      expect(find.text('This code was not found at your restaurant.'), findsOneWidget);
      expect(find.byKey(const Key('detailCode')), findsNothing);
    });

    testWidgets('an already used code cannot be confirmed again', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['USED11'] = reservationOf('USED11', status: ReservationState.redeemed);

      await checkCode(tester, 'used11');

      expect(tester.widget<Text>(find.byKey(const Key('detailStatus'))).data, 'Already used');
      expect(find.byKey(const Key('confirmCode')), findsNothing);
      expect(find.textContaining('off the bill'), findsNothing);
    });

    testWidgets('a code the customer cancelled cannot be confirmed', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['CANC11'] = reservationOf('CANC11', status: ReservationState.cancelled);

      await checkCode(tester, 'canc11');

      expect(tester.widget<Text>(find.byKey(const Key('detailStatus'))).data, 'Cancelled by the customer');
      expect(find.byKey(const Key('confirmCode')), findsNothing);
    });

    testWidgets('an expired code cannot be confirmed, even if the server still said active', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['OLD111'] = reservationOf('OLD111', expiresIn: const Duration(minutes: -1));

      await checkCode(tester, 'old111');

      expect(tester.widget<Text>(find.byKey(const Key('detailStatus'))).data, 'Expired');
      expect(find.byKey(const Key('confirmCode')), findsNothing);
    });

    testWidgets('if the server refuses the confirmation the reason shows and the waiter can retry', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['AB12CD'] = reservationOf('AB12CD');
      venue.redeemError = serverFailure(400, {
        'title': 'Validation failed',
        'errors': {
          'code': ['This code has already been used.'],
        },
      });
      await checkCode(tester, 'ab12cd');

      await tester.tap(find.byKey(const Key('confirmCode')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDialogYes')));
      await tester.pumpAndSettle();

      expect(find.text('This code has already been used.'), findsOneWidget);
      expect(find.byKey(const Key('confirmCode')), findsOneWidget);
    });
  });

  group('the reservations list', () {
    testWidgets('shows active reservations first and opens one ready to confirm', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['LIVE11'] = reservationOf('LIVE11');
      venue.reservations['USED11'] = reservationOf('USED11', status: ReservationState.redeemed);
      await goToTab(tester, 'Reservations');

      expect(find.byKey(const Key('reservation-LIVE11')), findsOneWidget);
      expect(find.byKey(const Key('reservation-USED11')), findsNothing, reason: 'only active ones by default');

      await tester.tap(find.byKey(const Key('reservation-LIVE11')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmCode')), findsOneWidget);
    });

    testWidgets('the filter switches between active, used and all', (tester) async {
      final venue = FakeVenueRepository(me: approvedStaff());
      venue.reservations['LIVE11'] = reservationOf('LIVE11');
      venue.reservations['USED11'] = reservationOf('USED11', status: ReservationState.redeemed);
      final app = AppHarness(session: testSession(roles: ['Staff']), venueRepository: venue);
      await app.pump(tester);
      await goToTab(tester, 'Reservations');

      await tester.tap(find.text('Used'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reservation-USED11')), findsOneWidget);
      expect(find.byKey(const Key('reservation-LIVE11')), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reservation-USED11')), findsOneWidget);
      expect(find.byKey(const Key('reservation-LIVE11')), findsOneWidget);
    });

    testWidgets('an empty list says so', (tester) async {
      await open(tester);
      await goToTab(tester, 'Reservations');

      expect(find.text('No reservations here.'), findsOneWidget);
    });
  });

  group('the owner\'s team', () {
    Future<FakeVenueRepository> openTeam(WidgetTester tester, List<StaffMember> staff) async {
      final (_, venue) = await open(tester, owner: true);
      venue.staff = staff;
      await goToTab(tester, 'Team');

      return venue;
    }

    testWidgets('waiters waiting for approval come first, with approve and decline', (tester) async {
      await openTeam(tester, [
        staffOf('o1', 'Anar Aliyev', owner: true),
        staffOf('w1', 'Waiter Wali', status: MemberStatus.pending, phone: '+994501112233'),
        staffOf('w2', 'Waiter Vusal'),
      ]);

      expect(find.text('Waiting for your approval'), findsOneWidget);
      expect(find.byKey(const Key('approve-w1')), findsOneWidget);
      expect(find.byKey(const Key('decline-w1')), findsOneWidget);
      expect(find.byKey(const Key('approve-w2')), findsNothing, reason: 'already approved');
      expect(find.textContaining('+994501112233'), findsOneWidget);
    });

    testWidgets('approving moves the waiter into the team', (tester) async {
      final venue = await openTeam(tester, [staffOf('w1', 'Waiter Wali', status: MemberStatus.pending)]);

      await tester.tap(find.byKey(const Key('approve-w1')));
      await tester.pumpAndSettle();

      expect(venue.approved, ['w1']);
      expect(find.text('Waiting for your approval'), findsNothing);
      expect(find.byKey(const Key('remove-w1')), findsOneWidget);
    });

    testWidgets('declining marks the request declined', (tester) async {
      final venue = await openTeam(tester, [staffOf('w1', 'Waiter Wali', status: MemberStatus.pending)]);

      await tester.tap(find.byKey(const Key('decline-w1')));
      await tester.pumpAndSettle();

      expect(venue.rejected, ['w1']);
      expect(find.textContaining('Declined'), findsOneWidget);
    });

    testWidgets('removing a waiter asks first', (tester) async {
      final venue = await openTeam(tester, [staffOf('w1', 'Waiter Wali')]);

      await tester.tap(find.byKey(const Key('remove-w1')));
      await tester.pumpAndSettle();
      expect(find.text('Remove Waiter Wali?'), findsOneWidget);
      expect(venue.removed, isEmpty);

      await tester.tap(find.byKey(const Key('removeDialogYes')));
      await tester.pumpAndSettle();

      expect(venue.removed, ['w1']);
      expect(find.text('Waiter Wali'), findsNothing);
    });

    testWidgets('the owner themself cannot be removed', (tester) async {
      await openTeam(tester, [staffOf('o1', 'Anar Aliyev', owner: true)]);

      expect(find.byKey(const Key('remove-o1')), findsNothing);
      expect(find.textContaining('Owner'), findsWidgets);
    });

    testWidgets('with nobody yet it explains how waiters join', (tester) async {
      await openTeam(tester, [staffOf('o1', 'Anar Aliyev', owner: true)]);

      expect(find.textContaining('No waiters yet'), findsOneWidget);
    });
  });

  group('asking HARA for a change', () {
    Future<FakeVenueRepository> openRestaurant(WidgetTester tester) async {
      final (_, venue) = await open(tester, owner: true);
      await goToTab(tester, 'Restaurant');

      return venue;
    }

    Future<void> openForm(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.tap(find.byKey(const Key('requestChange')));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the restaurant and earlier requests with HARA\'s answers', (tester) async {
      final (_, venue) = await open(tester, owner: true);
      venue.changeRequests = [
        ChangeRequest(id: 'a', status: ChangeRequestState.rejected, createdAt: DateTime.now(), name: 'New name', adminNote: 'Not possible'),
        ChangeRequest(id: 'b', status: ChangeRequestState.approved, createdAt: DateTime.now(), discountPercent: 15),
        ChangeRequest(id: 'c', status: ChangeRequestState.pending, createdAt: DateTime.now(), address: 'Baku, Fizuli 5'),
      ];
      await goToTab(tester, 'Restaurant');

      expect(find.text('Cafe One'), findsWidgets);
      expect(find.textContaining('Discount: 10%'), findsOneWidget);
      expect(find.textContaining('Declined'), findsOneWidget);
      expect(find.textContaining('Reply: Not possible'), findsOneWidget);
      expect(find.textContaining('Approved'), findsOneWidget);
      expect(find.textContaining('Waiting for review'), findsOneWidget);
    });

    testWidgets('with no requests yet it says so', (tester) async {
      await openRestaurant(tester);

      expect(find.text('No requests yet.'), findsOneWidget);
    });

    testWidgets('an empty form is refused', (tester) async {
      final venue = await openRestaurant(tester);
      await openForm(tester);

      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nothingFilled')), findsOneWidget);
      expect(venue.createdRequests, isEmpty);
    });

    testWidgets('a discount outside 0-100 is refused', (tester) async {
      final venue = await openRestaurant(tester);
      await openForm(tester);

      await tester.enterText(find.byKey(const Key('discount')), '150');
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();

      expect(find.text('Enter a number from 0 to 100.'), findsOneWidget);
      expect(venue.createdRequests, isEmpty);
    });

    testWidgets('sends only what was filled in, then shows the new request as waiting', (tester) async {
      final venue = await openRestaurant(tester);
      await openForm(tester);

      await tester.enterText(find.byKey(const Key('name')), '  Cafe One Deluxe ');
      await tester.enterText(find.byKey(const Key('discount')), '20');
      await tester.enterText(find.byKey(const Key('descriptionEn')), 'Now with a terrace');
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();

      expect(venue.createdRequests.single, {
        'name': 'Cafe One Deluxe',
        'address': null,
        'phoneNumber': null,
        'description': null,
        'descriptionRu': null,
        'descriptionEn': 'Now with a terrace',
        'discountPercent': 20,
        'ownerNote': null,
      });
      expect(find.text('Request sent. HARA will review it.'), findsOneWidget);
      expect(find.byKey(const Key('requestChange')), findsOneWidget, reason: 'back on the restaurant tab');
      expect(find.textContaining('Waiting for review'), findsOneWidget);
    });

    testWidgets('the form shows what the restaurant has now', (tester) async {
      await openRestaurant(tester);
      await openForm(tester);

      expect(find.text('Now: Cafe One'), findsOneWidget);
      expect(find.text('Now: Baku, Nizami 1'), findsOneWidget);
      expect(find.text('Now: 10%'), findsOneWidget);
    });

    testWidgets('if the server refuses, the message shows and the form stays', (tester) async {
      final venue = await openRestaurant(tester);
      venue.createRequestError = serverFailure(400, {
        'title': 'Validation failed',
        'errors': {
          'changes': ['You already have several requests waiting for review. Please wait for an answer first.'],
        },
      });
      await openForm(tester);

      await tester.enterText(find.byKey(const Key('name')), 'Another name');
      await tester.tap(find.byKey(const Key('submit')));
      await tester.pumpAndSettle();

      expect(find.textContaining('several requests waiting'), findsOneWidget);
      expect(find.byKey(const Key('submit')), findsOneWidget);
    });
  });
}
