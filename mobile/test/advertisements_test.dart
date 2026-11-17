import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/advertisements/data/advertisement.dart';
import 'package:hara/features/restaurants/data/restaurant.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';

class _Capture implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);

    return ResponseBody.fromString(
      '[{"id":"x","title":"Bank","imageUrl":"/uploads/ads/x.jpg","linkUrl":"bank.az/offer","sortOrder":1,"isActive":true,"createdAt":"2030-01-01T00:00:00Z"}]',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _ad = Advertisement(id: 'a1', imageUrl: '/uploads/ads/a1.jpg', title: 'Bank', linkUrl: 'bank.az/offer');
const _adNoLink = Advertisement(id: 'a2', imageUrl: '/uploads/ads/a2.jpg', title: 'Brand');

Restaurant _r(String id, String name) => Restaurant(id: id, name: name, address: 'Baku', latitude: 40.4, longitude: 49.8);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('a banner', () {
    test('is read from the server\'s list', () async {
      final adapter = _Capture();
      final repository = AdvertisementsRepository(ApiClient()..dio.httpClientAdapter = adapter);

      final ads = await repository.getAdvertisements();

      expect(adapter.requests.single.path, '/api/advertisements');
      expect(ads.single.title, 'Bank');
      expect(ads.single.imageUri.path, '/uploads/ads/x.jpg');
    });

    test('opens a web address, adding https when the admin left it out', () {
      expect(_ad.uri.toString(), 'https://bank.az/offer');
      expect(const Advertisement(id: 'b', imageUrl: 'x', linkUrl: 'http://a.az/x').uri.toString(), 'http://a.az/x');
    });

    test('has no address to open when there is none, or when it is not a web address', () {
      expect(_adNoLink.uri, isNull);
      expect(const Advertisement(id: 'c', imageUrl: 'x', linkUrl: '   ').uri, isNull);
      expect(const Advertisement(id: 'd', imageUrl: 'x', linkUrl: 'tel:+994501234567').uri, isNull);
      expect(const Advertisement(id: 'e', imageUrl: 'x', linkUrl: 'javascript:alert(1)').uri, isNull);
    });
  });

  group('on the home screen', () {
    Future<AppHarness> open(WidgetTester tester, {List<Advertisement> ads = const [], void Function(Uri)? onOpen}) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = AppHarness(
        continuedAsCustomer: true,
        restaurants: [_r('a', 'Alpha'), _r('b', 'Bravo')],
        advertisements: ads,
        adLinkOpener: onOpen == null ? null : (context, uri) async => onOpen(uri),
      );
      await app.pump(tester);

      return app;
    }

    testWidgets('a banner shows, marked as an ad', (tester) async {
      await open(tester, ads: [_ad]);

      expect(find.byKey(const Key('adBanner')), findsOneWidget);
      expect(find.byKey(const Key('ad-a1')), findsOneWidget);
      expect(find.text('Ad'), findsOneWidget);
    });

    testWidgets('no banners, no space for them', (tester) async {
      await open(tester);

      expect(find.byKey(const Key('adBanner')), findsNothing);
    });

    testWidgets('tapping a banner opens its address', (tester) async {
      Uri? opened;
      await open(tester, ads: [_ad], onOpen: (uri) => opened = uri);

      await tester.tap(find.byKey(const Key('ad-a1')));
      await tester.pumpAndSettle();

      expect(opened.toString(), 'https://bank.az/offer');
    });

    testWidgets('a banner with no address does nothing when tapped', (tester) async {
      Uri? opened;
      await open(tester, ads: [_adNoLink], onOpen: (uri) => opened = uri);

      await tester.tap(find.byKey(const Key('ad-a2')));
      await tester.pumpAndSettle();

      expect(opened, isNull);
    });

    testWidgets('several banners can be swiped through', (tester) async {
      await open(tester, ads: [_ad, _adNoLink]);

      expect(find.byKey(const Key('ad-a1')), findsOneWidget);

      await tester.drag(find.byKey(const Key('adBanner')), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ad-a2')), findsOneWidget);
    });

    testWidgets('they turn by themselves', (tester) async {
      await open(tester, ads: [_ad, _adNoLink]);

      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ad-a2')), findsOneWidget);
    });

    testWidgets('searching removes the banner: the person wants a restaurant', (tester) async {
      await open(tester, ads: [_ad]);

      await tester.enterText(find.byType(TextField), 'Alp');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('adBanner')), findsNothing);
    });
  });
}
