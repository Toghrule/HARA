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
    // With six tabs the last ones sit beyond the screen's edge; the tab bar scrolls, like on a phone.
    await tester.ensureVisible(find.widgetWithText(Tab, label));
    await tester.tap(find.widgetWithText(Tab, label));
    await tester.pumpAndSettle();
  }

  group('the tabs', () {
    testWidgets('a waiter answers requests, confirms codes and sees reservations, nothing else', (tester) async {
      await open(tester);

      expect(find.text('Cafe One'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Requests'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Confirm code'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Reservations'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Statistics'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Team'), findsNothing);
      expect(find.widgetWithText(Tab, 'Restaurant'), findsNothing);
    });

    testWidgets('the owner also gets the team and the restaurant', (tester) async {
      await open(tester, owner: true);

      expect(find.widgetWithText(Tab, 'Team'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Restaurant'), findsOneWidget);
    });
  });

  group('statistics', () {
    testWidgets('the owner sees the restaurant\'s day, month and year, and their own count', (tester) async {
      final (_, venue) = await open(tester, owner: true);
      venue.stats = const VenueStats(
        today: PeriodCounts(accepted: 3, redeemed: 2),
        thisMonth: PeriodCounts(accepted: 40, redeemed: 31),
        thisYear: PeriodCounts(accepted: 400, redeemed: 310),
        redeemedByMeToday: 1,
      );

      await goToTab(tester, 'Statistics');

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This month'), findsOneWidget);
      expect(find.text('This year'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('today-accepted'))).data, '3');
      expect(tester.widget<Text>(find.byKey(const Key('today-came'))).data, '2');
      expect(tester.widget<Text>(find.byKey(const Key('month-accepted'))).data, '40');
      expect(tester.widget<Text>(find.byKey(const Key('month-came'))).data, '31');
      expect(tester.widget<Text>(find.byKey(const Key('year-accepted'))).data, '400');
      expect(tester.widget<Text>(find.byKey(const Key('year-came'))).data, '310');
      expect(tester.widget<Text>(find.byKey(const Key('statsMine'))).data, '1');
    });

    testWidgets('a waiter sees only how many codes they confirmed today', (tester) async {
      final (_, venue) = await open(tester);
      venue.stats = const VenueStats(redeemedByMeToday: 4);

      await goToTab(tester, 'Statistics');

      expect(find.text('Codes you confirmed today'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('statsMine'))).data, '4');
      expect(find.text('Today'), findsNothing);
      expect(find.text('This month'), findsNothing);
      expect(find.text('This year'), findsNothing);
    });

    testWidgets('a failed load says so and can be retried', (tester) async {
      final (_, venue) = await open(tester);
      venue.statsError = serverFailure(500);

      await goToTab(tester, 'Statistics');

      expect(find.byKey(const Key('statsMine')), findsNothing);
      expect(find.text('Retry'), findsOneWidget);

      venue.statsError = null;
      venue.stats = const VenueStats(redeemedByMeToday: 2);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('statsMine'))).data, '2');
    });
  });

  group('confirming a code', () {
    Future<void> checkCode(WidgetTester tester, String typed) async {
      await goToTab(tester, 'Confirm code');
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
  group('customers\' requests', () {
    Future<FakeVenueRepository> openRequests(WidgetTester tester, {bool owner = false}) async {
      final (_, venue) = await open(tester, owner: owner);
      venue.reservations['OLDER1'] = reservationOf('OLDER1', status: ReservationState.pending, expiresIn: const Duration(minutes: 10), age: const Duration(minutes: 5), phone: '+994501110001');
      venue.reservations['NEWER2'] = reservationOf('NEWER2', status: ReservationState.pending, expiresIn: const Duration(minutes: 14), age: const Duration(minutes: 1), phone: '+994501110002');

      return venue;
    }

    /// The screens fetch the waiting requests again every 10 seconds; let that happen.
    Future<void> reload(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();
    }

    testWidgets('the first tab shows requests waiting for an answer, oldest first', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['OLDER1'] = reservationOf('OLDER1', status: ReservationState.pending, age: const Duration(minutes: 5), phone: '+994501110001');
      venue.reservations['NEWER2'] = reservationOf('NEWER2', status: ReservationState.pending, age: const Duration(minutes: 1), phone: '+994501110002');
      await reload(tester);

      expect(find.byKey(const Key('request-OLDER1')), findsOneWidget);
      expect(find.byKey(const Key('request-NEWER2')), findsOneWidget);
      expect(find.text('+994501110001'), findsOneWidget);
      expect(find.textContaining('Answer within'), findsNWidgets(2));
      final older = tester.getTopLeft(find.byKey(const Key('request-OLDER1'))).dy;
      final newer = tester.getTopLeft(find.byKey(const Key('request-NEWER2'))).dy;
      expect(older, lessThan(newer), reason: 'whoever asked first is answered first');
    });

    testWidgets('with nothing waiting it says so', (tester) async {
      await open(tester);

      expect(find.byKey(const Key('noRequests')), findsOneWidget);
    });

    testWidgets('requests that are already answered, cancelled or out of time are not listed', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['LIVE11'] = reservationOf('LIVE11', status: ReservationState.pending);
      venue.reservations['DONE22'] = reservationOf('DONE22');
      venue.reservations['CANC33'] = reservationOf('CANC33', status: ReservationState.cancelled);
      venue.reservations['LATE44'] = reservationOf('LATE44', status: ReservationState.pending, expiresIn: const Duration(minutes: -1));
      await reload(tester);

      expect(find.byKey(const Key('request-LIVE11')), findsOneWidget);
      expect(find.byKey(const Key('request-DONE22')), findsNothing);
      expect(find.byKey(const Key('request-CANC33')), findsNothing);
      expect(find.byKey(const Key('request-LATE44')), findsNothing);
    });

    testWidgets('a badge on the tab counts the waiting requests', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['OLDER1'] = reservationOf('OLDER1', status: ReservationState.pending);
      venue.reservations['NEWER2'] = reservationOf('NEWER2', status: ReservationState.pending);
      await reload(tester);

      expect(find.byKey(const Key('badge-Requests')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('badge-Requests')), matching: find.text('2')), findsOneWidget);
    });

    testWidgets('a new request shows up by itself within seconds, even from another tab', (tester) async {
      final (_, venue) = await open(tester);
      await goToTab(tester, 'Reservations');
      expect(find.byKey(const Key('badge-Requests')), findsNothing);

      venue.reservations['NEWER2'] = reservationOf('NEWER2', status: ReservationState.pending);
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('badge-Requests')), findsOneWidget);
      await goToTab(tester, 'Requests');
      expect(find.byKey(const Key('request-NEWER2')), findsOneWidget);
    });

    testWidgets('accepting starts the customer\'s 30 minutes and takes the request off the list', (tester) async {
      final venue = await openRequests(tester);
      await reload(tester);

      await tester.tap(find.byKey(const Key('accept-OLDER1')));
      await tester.pumpAndSettle();

      expect(venue.accepted, ['OLDER1']);
      expect(find.text('Accepted. The customer\'s 30 minutes have started.'), findsOneWidget);
      expect(find.byKey(const Key('request-OLDER1')), findsNothing);
      expect(find.byKey(const Key('request-NEWER2')), findsOneWidget);
      expect(venue.reservations['OLDER1']!.status, ReservationState.active);
    });

    testWidgets('declining takes the request off the list', (tester) async {
      final venue = await openRequests(tester);
      await reload(tester);

      await tester.tap(find.byKey(const Key('decline-NEWER2')));
      await tester.pumpAndSettle();

      expect(venue.declined, ['NEWER2']);
      expect(find.text('Declined.'), findsOneWidget);
      expect(find.byKey(const Key('request-NEWER2')), findsNothing);
    });

    testWidgets('if the server refuses, the reason shows and the request stays', (tester) async {
      final venue = await openRequests(tester);
      venue.answerError = serverFailure(400, {
        'title': 'Validation failed',
        'errors': {
          'code': ['This request is no longer waiting for an answer.'],
        },
      });
      await reload(tester);

      await tester.tap(find.byKey(const Key('accept-OLDER1')));
      await tester.pumpAndSettle();

      expect(find.text('This request is no longer waiting for an answer.'), findsOneWidget);
      expect(find.byKey(const Key('request-OLDER1')), findsOneWidget);
    });

    testWidgets('a waiter and an owner both answer', (tester) async {
      final venue = await openRequests(tester, owner: true);
      await reload(tester);

      await tester.tap(find.byKey(const Key('accept-OLDER1')));
      await tester.pumpAndSettle();

      expect(venue.accepted, ['OLDER1']);
    });

    testWidgets('a waiting request cannot be confirmed at the venue, it must be accepted first', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['WAIT11'] = reservationOf('WAIT11', status: ReservationState.pending, expiresIn: const Duration(minutes: 9));
      await goToTab(tester, 'Confirm code');

      await tester.enterText(find.byKey(const Key('codeInput')), 'wait11');
      await tester.tap(find.byKey(const Key('checkCode')));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('detailStatus'))).data, 'Waiting for your answer');
      expect(find.byKey(const Key('confirmCode')), findsNothing);
      expect(find.byKey(const Key('acceptRequest')), findsOneWidget);
      expect(find.byKey(const Key('declineRequest')), findsOneWidget);
      expect(find.textContaining('off the bill'), findsNothing);
    });

    testWidgets('accepting from the code card turns it into a confirmable reservation', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['WAIT11'] = reservationOf('WAIT11', status: ReservationState.pending, expiresIn: const Duration(minutes: 9), discountPercent: 12);
      await goToTab(tester, 'Confirm code');
      await tester.enterText(find.byKey(const Key('codeInput')), 'wait11');
      await tester.tap(find.byKey(const Key('checkCode')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('acceptRequest')));
      await tester.pumpAndSettle();

      expect(venue.accepted, ['WAIT11']);
      expect(find.byKey(const Key('acceptedNote')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('detailStatus'))).data, 'Valid');
      expect(find.text('Give 12% off the bill.'), findsOneWidget);
      expect(find.byKey(const Key('confirmCode')), findsOneWidget, reason: 'ready for when the customer arrives');
      expect(find.byKey(const Key('acceptRequest')), findsNothing);
    });

    testWidgets('a request whose time to answer ran out cannot be accepted any more', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['LATE44'] = reservationOf('LATE44', status: ReservationState.pending, expiresIn: const Duration(minutes: -1));
      await goToTab(tester, 'Confirm code');

      await tester.enterText(find.byKey(const Key('codeInput')), 'late44');
      await tester.tap(find.byKey(const Key('checkCode')));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('detailStatus'))).data, 'Not answered in time');
      expect(find.byKey(const Key('acceptRequest')), findsNothing);
      expect(find.byKey(const Key('confirmCode')), findsNothing);
    });

    testWidgets('a declined request shows as declined and offers nothing', (tester) async {
      final (_, venue) = await open(tester);
      venue.reservations['NOPE55'] = reservationOf('NOPE55', status: ReservationState.declined);
      await goToTab(tester, 'Confirm code');

      await tester.enterText(find.byKey(const Key('codeInput')), 'nope55');
      await tester.tap(find.byKey(const Key('checkCode')));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('detailStatus'))).data, 'Declined');
      expect(find.byKey(const Key('acceptRequest')), findsNothing);
      expect(find.byKey(const Key('confirmCode')), findsNothing);
    });
  });

}
