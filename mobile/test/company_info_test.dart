import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hara/core/network/api_client.dart';
import 'package:hara/features/company_info/data/about_us.dart';
import 'package:hara/features/company_info/data/company_info_repository.dart';
import 'package:hara/features/company_info/data/contact_info.dart';
import 'package:hara/features/company_info/data/social_link.dart';
import 'package:hara/features/company_info/presentation/screens/about_screen.dart';
import 'package:hara/features/company_info/presentation/screens/contact_screen.dart';
import 'package:hara/features/faq/data/faq_item.dart';
import 'package:hara/features/faq/data/faq_repository.dart';
import 'package:hara/features/faq/presentation/screens/faq_screen.dart';

class _FakeCompanyInfoRepository extends CompanyInfoRepository {
  _FakeCompanyInfoRepository({
    this.about = const AboutUs(companyName: '', description: ''),
    this.contacts = const [],
    this.socialLinks = const [],
    this.aboutError,
  }) : super(ApiClient());

  final AboutUs about;
  final List<ContactInfo> contacts;
  final List<SocialLink> socialLinks;
  final Object? aboutError;

  @override
  Future<AboutUs> getAboutUs() async {
    if (aboutError != null) throw aboutError!;
    return about;
  }

  @override
  Future<List<ContactInfo>> getContacts() async => contacts;

  @override
  Future<List<SocialLink>> getSocialLinks() async => socialLinks;
}

class _FakeFaqRepository extends FaqRepository {
  _FakeFaqRepository({this.items = const [], this.failuresBeforeSuccess = 0}) : super(ApiClient());

  final List<FaqItem> items;
  int failuresBeforeSuccess;
  int calls = 0;

  @override
  Future<List<FaqItem>> getFaqItems() async {
    calls++;
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw DioException(requestOptions: RequestOptions(path: '/api/faq'));
    }
    return items;
  }
}

const _about = AboutUs(
  companyName: 'HARA',
  description: 'We help you find a new place to go.',
);

const _contacts = [
  ContactInfo(type: ContactType.phone, value: '+994 50 123 45 67', label: 'Support line'),
  ContactInfo(type: ContactType.email, value: 'hello@hara.az'),
];

const _socialLinks = [
  SocialLink(platform: SocialPlatform.instagram, url: 'https://instagram.com/hara'),
  SocialLink(platform: SocialPlatform.facebook, url: 'facebook.com/hara'),
];

const _faqItems = [
  FaqItem(question: 'Is HARA free?', answer: 'Yes, customers never pay.'),
  FaqItem(question: 'How long is a reservation?', answer: '30 or 60 minutes.'),
];

Future<void> _pumpApp(
  WidgetTester tester, {
  required String initialLocation,
  _FakeCompanyInfoRepository? companyInfo,
  _FakeFaqRepository? faq,
}) async {
  // Phone-sized, so nothing is pushed out of the viewport and left unbuilt by the lazy list.
  tester.view.physicalSize = const Size(500, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Scaffold(body: Text('HOME'))),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(path: '/contact', builder: (context, state) => const ContactScreen()),
      GoRoute(path: '/faq', builder: (context, state) => const FaqScreen()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        companyInfoRepositoryProvider.overrideWithValue(companyInfo ?? _FakeCompanyInfoRepository()),
        faqRepositoryProvider.overrideWithValue(faq ?? _FakeFaqRepository()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ContactInfo', () {
    test('phone numbers open the dialer, with spaces and dashes removed', () {
      const phone = ContactInfo(type: ContactType.phone, value: '+994 50 123-45-67');

      expect(phone.uri.toString(), 'tel:+994501234567');
    });

    test('emails open the mail app; values that are not an email do nothing', () {
      expect(const ContactInfo(type: ContactType.email, value: 'hello@hara.az').uri.toString(), 'mailto:hello@hara.az');
      expect(const ContactInfo(type: ContactType.email, value: 'not an email').uri, isNull);
      expect(const ContactInfo(type: ContactType.phone, value: 'call us!').uri, isNull);
      expect(const ContactInfo(type: ContactType.other, value: 'Baku').uri, isNull);
    });

    test('the title is the admin\'s label, or the type when there is none', () {
      expect(const ContactInfo(type: ContactType.phone, value: '1', label: ' Support ').title, 'Support');
      expect(const ContactInfo(type: ContactType.phone, value: '1').title, 'Phone');
      expect(const ContactInfo(type: ContactType.email, value: 'a@b.c', label: '  ').title, 'Email');
    });

    test('fromJson reads the API shape, treating an unknown type as other', () {
      final contact = ContactInfo.fromJson({
        'id': 'x',
        'type': 7,
        'value': 'Baku office',
        'label': null,
        'sortOrder': 1,
        'isActive': true,
      });

      expect(contact.type, ContactType.other);
      expect(contact.value, 'Baku office');
    });
  });

  group('SocialLink', () {
    Uri? uriOf(String url) => SocialLink(platform: SocialPlatform.website, url: url).uri;

    test('keeps http(s) links and adds https:// when the admin left it out', () {
      expect(uriOf('https://instagram.com/hara').toString(), 'https://instagram.com/hara');
      expect(uriOf('http://example.com').toString(), 'http://example.com');
      expect(uriOf('  instagram.com/hara ').toString(), 'https://instagram.com/hara');
    });

    test('refuses anything that is not a web address', () {
      expect(uriOf('javascript:alert(1)'), isNull);
      expect(uriOf('ftp://files.example.com'), isNull);
      expect(uriOf('tel:+994501234567'), isNull);
      expect(uriOf(''), isNull);
    });

    test('maps the API platform numbers, with unknown ones becoming a plain link', () {
      expect(SocialPlatform.fromApi(4), SocialPlatform.youTube);
      expect(SocialPlatform.fromApi(99), SocialPlatform.other);
      expect(SocialPlatform.fromApi(123), SocialPlatform.other);
    });
  });

  group('AboutUs', () {
    test('the blank answer the API gives before an admin writes anything counts as empty', () {
      final about = AboutUs.fromJson({
        'id': '00000000-0000-0000-0000-000000000000',
        'companyName': '',
        'description': '',
        'logoUrl': null,
        'lastModifiedAt': null,
      });

      expect(about.isEmpty, isTrue);
      expect(about.logoUri, isNull);
      expect(_about.isEmpty, isFalse);
    });

    test('the logo path is turned into a full URL', () {
      const about = AboutUs(companyName: 'HARA', description: '', logoUrl: '/uploads/about/logo.png');

      expect(about.logoUri.toString(), 'http://localhost:5080/uploads/about/logo.png');
    });
  });

  group('FaqScreen', () {
    testWidgets('lists the questions collapsed and reveals an answer on tap', (tester) async {
      await _pumpApp(tester, initialLocation: '/faq', faq: _FakeFaqRepository(items: _faqItems));

      expect(find.text('Is HARA free?'), findsOneWidget);
      expect(find.text('How long is a reservation?'), findsOneWidget);
      expect(find.text('Yes, customers never pay.'), findsNothing);

      await tester.tap(find.text('Is HARA free?'));
      await tester.pumpAndSettle();

      expect(find.text('Yes, customers never pay.'), findsOneWidget);
      expect(find.text('30 or 60 minutes.'), findsNothing);
    });

    testWidgets('says so when there are no questions', (tester) async {
      await _pumpApp(tester, initialLocation: '/faq');

      expect(find.text('No questions yet.'), findsOneWidget);
    });

    testWidgets('shows a readable error and recovers when the user retries', (tester) async {
      final faq = _FakeFaqRepository(items: _faqItems, failuresBeforeSuccess: 1);
      await _pumpApp(tester, initialLocation: '/faq', faq: faq);

      expect(find.textContaining('Can\'t reach the server'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(faq.calls, 2);
      expect(find.text('Is HARA free?'), findsOneWidget);
    });
  });

  group('ContactScreen', () {
    testWidgets('lists the contact details with their labels', (tester) async {
      await _pumpApp(
        tester,
        initialLocation: '/contact',
        companyInfo: _FakeCompanyInfoRepository(contacts: _contacts),
      );

      expect(find.text('Support line'), findsOneWidget);
      expect(find.text('+994 50 123 45 67'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget); // no label, so the type is the title
      expect(find.text('hello@hara.az'), findsOneWidget);
    });

    testWidgets('says so when there are no contact details', (tester) async {
      await _pumpApp(tester, initialLocation: '/contact');

      expect(find.text('No contact details yet.'), findsOneWidget);
    });
  });

  group('AboutScreen', () {
    testWidgets('shows the company text, social links and the way on to contact and FAQ', (tester) async {
      await _pumpApp(
        tester,
        initialLocation: '/about',
        companyInfo: _FakeCompanyInfoRepository(about: _about, socialLinks: _socialLinks),
      );

      expect(find.text('HARA'), findsOneWidget);
      expect(find.text('We help you find a new place to go.'), findsOneWidget);
      expect(find.text('Follow us'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('Contact us'), findsOneWidget);
      expect(find.text('Frequently asked questions'), findsOneWidget);
    });

    testWidgets('leaves out a social link that cannot be opened, and the heading if none can', (tester) async {
      await _pumpApp(
        tester,
        initialLocation: '/about',
        companyInfo: _FakeCompanyInfoRepository(
          about: _about,
          socialLinks: const [
            SocialLink(platform: SocialPlatform.instagram, url: 'https://instagram.com/hara'),
            SocialLink(platform: SocialPlatform.website, url: 'javascript:alert(1)'),
          ],
        ),
      );

      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('javascript:alert(1)'), findsNothing);

      await _pumpApp(
        tester,
        initialLocation: '/about',
        companyInfo: _FakeCompanyInfoRepository(
          about: _about,
          socialLinks: const [SocialLink(platform: SocialPlatform.website, url: 'javascript:alert(1)')],
        ),
      );

      expect(find.text('Follow us'), findsNothing);
    });

    testWidgets('while the admin has written nothing yet it still works, with a friendly note', (tester) async {
      await _pumpApp(tester, initialLocation: '/about');

      expect(find.text('More about us is coming soon.'), findsOneWidget);
      expect(find.text('Follow us'), findsNothing);
      expect(find.text('Contact us'), findsOneWidget);
    });

    testWidgets('an error loading the text shows a retry, without hiding contact and FAQ', (tester) async {
      await _pumpApp(
        tester,
        initialLocation: '/about',
        companyInfo: _FakeCompanyInfoRepository(
          aboutError: DioException(requestOptions: RequestOptions(path: '/api/company-info/about')),
        ),
      );

      expect(find.textContaining('Can\'t reach the server'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
      expect(find.text('Contact us'), findsOneWidget);
    });

    testWidgets('leads on to the contact and FAQ screens', (tester) async {
      await _pumpApp(
        tester,
        initialLocation: '/about',
        companyInfo: _FakeCompanyInfoRepository(about: _about, contacts: _contacts),
        faq: _FakeFaqRepository(items: _faqItems),
      );

      await tester.tap(find.text('Contact us'));
      await tester.pumpAndSettle();
      expect(find.text('hello@hara.az'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Frequently asked questions'));
      await tester.pumpAndSettle();
      expect(find.text('Is HARA free?'), findsOneWidget);
    });
  });
}
