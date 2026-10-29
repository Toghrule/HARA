import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/features/restaurants/data/opening_hours.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:hara/features/restaurants/presentation/availability_text.dart';
import 'package:hara/l10n/app_localizations_az.dart';
import 'package:hara/l10n/app_localizations_en.dart';
import 'package:hara/l10n/app_localizations_ru.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';

const _closedTomorrow = Availability(
  acceptingRequests: false,
  reason: AvailabilityReason.closed,
  nextOpensInDays: 1,
  nextOpensDay: 5,
  nextOpensAt: '10:00',
);

List<DayHours> _week({int? closedDay}) => [
      for (final day in weekFromMonday)
        day == closedDay ? DayHours(day: day, isClosed: true) : DayHours(day: day, isClosed: false, opens: '10:00', closes: '23:00'),
    ];

Restaurant _cafe(String id, String name, {Availability availability = Availability.open, List<DayHours> hours = const []}) => Restaurant(
      id: id,
      name: name,
      address: 'Baku, $name street',
      latitude: 40.4,
      longitude: 49.8,
      openingHours: hours,
      availability: availability,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('reading the server answer', () {
    Map<String, dynamic> json(Map<String, Object?> extra) => {
          'id': 'r',
          'name': 'N',
          'address': 'A',
          'latitude': 1,
          'longitude': 2,
          ...extra,
        };

    test('hours and availability are read', () {
      final restaurant = Restaurant.fromJson(json({
        'openingHours': [
          {'day': 1, 'isClosed': false, 'opens': '10:00', 'closes': '23:00'},
          {'day': 0, 'isClosed': true, 'opens': null, 'closes': null},
        ],
        'availability': {
          'acceptingRequests': false,
          'reason': 2,
          'closesAt': null,
          'nextOpensInDays': 1,
          'nextOpensDay': 5,
          'nextOpensAt': '10:00',
        },
      }));

      expect(restaurant.openingHours.map((d) => d.day), [1, 0]);
      expect(restaurant.openingHours.last.isClosed, isTrue);
      expect(restaurant.availability.acceptingRequests, isFalse);
      expect(restaurant.availability.reason, AvailabilityReason.closed);
      expect(restaurant.availability.nextOpensAt, '10:00');
    });

    test('an older server that sends nothing means open, no hours', () {
      final restaurant = Restaurant.fromJson(json({}));

      expect(restaurant.openingHours, isEmpty);
      expect(restaurant.availability.acceptingRequests, isTrue);
    });
  });

  group('the sentences', () {
    final en = AppLocalizationsEn();

    test('open, closing soon and closed', () {
      expect(availabilityText(en, const Availability(acceptingRequests: true, reason: AvailabilityReason.open, closesAt: '23:00')), 'Open until 23:00');
      expect(availabilityText(en, const Availability(acceptingRequests: false, reason: AvailabilityReason.closingSoon, closesAt: '23:00')), 'Closing at 23:00, not taking requests now');
      expect(availabilityText(en, _closedTomorrow), 'Closed, opens tomorrow at 10:00');
      expect(
        availabilityText(en, const Availability(acceptingRequests: false, reason: AvailabilityReason.closed, nextOpensInDays: 0, nextOpensDay: 4, nextOpensAt: '10:00')),
        'Closed, opens today at 10:00',
      );
      expect(
        availabilityText(en, const Availability(acceptingRequests: false, reason: AvailabilityReason.closed, nextOpensInDays: 3, nextOpensDay: 2, nextOpensAt: '12:30')),
        'Closed, opens on Tuesday at 12:30',
      );
      expect(availabilityText(en, const Availability(acceptingRequests: false, reason: AvailabilityReason.closed)), 'Closed');
    });

    test('weekday names in all three languages (the server counts Sunday as 0)', () {
      expect(AppLocalizationsEn().weekdayName('0'), 'Sunday');
      expect(AppLocalizationsAz().weekdayName('1'), 'Bazar ertəsi');
      expect(AppLocalizationsRu().weekdayName('6'), 'Суббота');
      const wednesdayOpening = Availability(acceptingRequests: false, reason: AvailabilityReason.closed, nextOpensInDays: 3, nextOpensDay: 3, nextOpensAt: '10:00');
      expect(availabilityText(AppLocalizationsAz(), wednesdayOpening), 'Bağlıdır, Çərşənbə günü saat 10:00-da açılır');
      expect(availabilityText(AppLocalizationsRu(), wednesdayOpening), 'Закрыто, откроется в среду в 10:00');
    });

    test('a day: closed, all day, or from to', () {
      expect(dayHoursText(en, const DayHours(day: 1, isClosed: true)), 'Closed');
      expect(dayHoursText(en, const DayHours(day: 1, isClosed: false, opens: '00:00', closes: '00:00')), 'Open 24 hours');
      expect(dayHoursText(en, const DayHours(day: 1, isClosed: false, opens: '18:00', closes: '02:00')), '18:00 – 02:00');
    });
  });

  group('the customer', () {
    Future<AppHarness> openList(WidgetTester tester, List<Restaurant> restaurants) async {
      final app = AppHarness(continuedAsCustomer: true, restaurants: restaurants);
      await app.pump(tester);

      return app;
    }

    Finder reserveButtonOf(String name) => find.descendant(
          of: find.widgetWithText(ListTile, name),
          matching: find.widgetWithText(FilledButton, 'Reserve'),
        );

    testWidgets('a closed restaurant says so and its reserve button is off', (tester) async {
      await openList(tester, [
        _cafe('open', 'Open Cafe', availability: const Availability(acceptingRequests: true, reason: AvailabilityReason.open, closesAt: '23:00')),
        _cafe('shut', 'Shut Cafe', availability: _closedTomorrow),
      ]);

      expect(find.text('Baku, Shut Cafe street\nClosed, opens tomorrow at 10:00'), findsOneWidget);
      expect(tester.widget<FilledButton>(reserveButtonOf('Shut Cafe')).onPressed, isNull);

      // An open restaurant has nothing extra on its row, and can be reserved.
      expect(find.text('Baku, Open Cafe street'), findsOneWidget);
      expect(tester.widget<FilledButton>(reserveButtonOf('Open Cafe')).onPressed, isNotNull);
    });

    testWidgets('a restaurant that is closing soon takes no more requests either', (tester) async {
      await openList(tester, [
        _cafe('soon', 'Soon Cafe', availability: const Availability(acceptingRequests: false, reason: AvailabilityReason.closingSoon, closesAt: '23:00')),
      ]);

      expect(find.textContaining('Closing at 23:00, not taking requests now'), findsOneWidget);
      expect(tester.widget<FilledButton>(reserveButtonOf('Soon Cafe')).onPressed, isNull);
    });

    testWidgets('the detail page shows the status, the week with Monday first, and a switched-off button while closed', (tester) async {
      await openList(tester, [_cafe('shut', 'Shut Cafe', availability: _closedTomorrow, hours: _week(closedDay: 1))]);
      await tester.tap(find.text('Shut Cafe'));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('availability'))).data, 'Closed, opens tomorrow at 10:00');
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Reserve a table')).onPressed, isNull);

      await tester.tap(find.byKey(const Key('hoursTile')));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('hours-1'))).data, 'Closed');
      expect(tester.widget<Text>(find.byKey(const Key('hours-2'))).data, '10:00 – 23:00');
      expect(tester.getTopLeft(find.text('Monday')).dy, lessThan(tester.getTopLeft(find.text('Sunday')).dy));
    });

    testWidgets('a restaurant with no hours shows no hours at all and can be reserved', (tester) async {
      await openList(tester, [_cafe('free', 'Free Cafe')]);
      await tester.tap(find.text('Free Cafe'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hoursTile')), findsNothing);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Reserve a table')).onPressed, isNotNull);
    });
  });
}
