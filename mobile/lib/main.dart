import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_controller.dart';
import 'core/auth/session_storage.dart';
import 'core/l10n/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/customer_choice.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialLocale = await loadInitialLocale();
  const sessionStorage = SecureSessionStorage();
  final initialSession = await sessionStorage.read();
  final continuedAsCustomer = await loadContinuedAsCustomer();

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => LocaleController(initialLocale)),
        customerChoiceProvider.overrideWith((ref) => CustomerChoice(continuedAsCustomer)),
        authControllerProvider.overrideWith(
          (ref) => AuthController(ref.watch(authRepositoryProvider), sessionStorage, initialSession),
        ),
      ],
      child: const HaraApp(),
    ),
  );
}

class HaraApp extends ConsumerWidget {
  const HaraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'HARA',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
