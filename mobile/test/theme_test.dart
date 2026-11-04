import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/theme/app_theme.dart';
import 'package:hara/core/theme/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();

  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the two themes', () {
    test('light is cream with purple buttons and gold touches, dark is the logo\'s black with gold buttons', () {
      final light = AppTheme.light.colorScheme;
      final dark = AppTheme.dark.colorScheme;

      expect(light.brightness, Brightness.light);
      expect(light.surface, const Color(0xFFFBF3E6));
      expect(light.primary, AppTheme.deepPurple);
      expect(light.secondary, AppTheme.gold);

      expect(dark.brightness, Brightness.dark);
      expect(dark.surface, const Color(0xFF0F0A14));
      expect(dark.primary, AppTheme.gold);
      expect(dark.secondary, AppTheme.purple);
    });

    test('text and buttons are readable on their backgrounds in both themes (WCAG AA, 4.5)', () {
      for (final scheme in [AppTheme.light.colorScheme, AppTheme.dark.colorScheme]) {
        final pairs = {
          'text on page': (scheme.onSurface, scheme.surface),
          'text on a card': (scheme.onSurface, scheme.surfaceContainerLowest),
          'muted text on page': (scheme.onSurfaceVariant, scheme.surface),
          'button text': (scheme.onPrimary, scheme.primary),
          'error text': (scheme.error, scheme.surface),
          'tinted chip text': (scheme.onPrimaryContainer, scheme.primaryContainer),
          'secondary button text': (scheme.onSecondary, scheme.secondary),
        };
        pairs.forEach((name, pair) {
          expect(_contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5), reason: '$name (${scheme.brightness.name})');
        });
      }
    });

    test('the top bar is black with gold in both, so the logo always sits on its own black', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(theme.appBarTheme.backgroundColor, const Color(0xFF000000));
        expect(theme.appBarTheme.foregroundColor, AppTheme.gold);
      }
    });

    test('gold on the black bar is readable', () {
      expect(_contrast(AppTheme.gold, const Color(0xFF000000)), greaterThan(8));
    });
  });

  group('choosing light or dark', () {
    Future<ProviderContainer> container() async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(themeModeProvider);
      await Future<void>.delayed(Duration.zero);

      return c;
    }

    test('follows the phone until chosen', () async {
      final c = await container();

      expect(c.read(themeModeProvider), ThemeMode.system);
    });

    test('the choice is kept and found again next time', () async {
      final first = await container();
      await first.read(themeModeProvider.notifier).set(ThemeMode.dark);
      expect(first.read(themeModeProvider), ThemeMode.dark);
      expect((await SharedPreferences.getInstance()).getString('theme_mode'), 'dark');

      final second = await container();
      await Future<void>.delayed(Duration.zero);
      expect(second.read(themeModeProvider), ThemeMode.dark);
    });

    test('a saved value that means nothing leaves it on the phone\'s setting', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'purple'});
      final c = await container();
      await Future<void>.delayed(Duration.zero);

      expect(c.read(themeModeProvider), ThemeMode.system);
    });

    testWidgets('"About" has the switch, and the app changes at once', (tester) async {
      final app = AppHarness(continuedAsCustomer: true);
      await app.pump(tester);
      app.router.go('/about');
      await tester.pumpAndSettle();

      MaterialApp materialApp() => tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp().themeMode, ThemeMode.system);

      await tester.tap(find.descendant(of: find.byKey(const Key('themeMode')), matching: find.text('Dark')));
      await tester.pumpAndSettle();
      expect(materialApp().themeMode, ThemeMode.dark);
      expect(Theme.of(tester.element(find.byType(Scaffold).first)).colorScheme.primary, AppTheme.gold);

      await tester.tap(find.descendant(of: find.byKey(const Key('themeMode')), matching: find.text('Light')));
      await tester.pumpAndSettle();
      expect(materialApp().themeMode, ThemeMode.light);
      expect(Theme.of(tester.element(find.byType(Scaffold).first)).colorScheme.primary, AppTheme.deepPurple);
      expect((await SharedPreferences.getInstance()).getString('theme_mode'), 'light');
    });
  });

  group('the screens in both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('the restaurant list shows the logo and its chips, ${mode.name}', (tester) async {
        SharedPreferences.setMockInitialValues({'theme_mode': mode.name});
        final app = AppHarness(continuedAsCustomer: true);
        await app.pump(tester);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('appLogo')), findsOneWidget);
        expect(find.byKey(const Key('chip-open')), findsOneWidget);
        expect(find.text('Cafe One'), findsOneWidget);
        final scheme = Theme.of(tester.element(find.byType(Scaffold).first)).colorScheme;
        expect(scheme.brightness, mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
      });
    }
  });
}
