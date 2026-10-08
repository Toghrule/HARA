import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Languages the app speaks. Azerbaijani is the default.
const supportedLanguageCodes = ['az', 'ru', 'en'];
const defaultLanguageCode = 'az';

const _preferenceKey = 'language';

/// The language to start with: the one the user picked last time, else the phone's language if the
/// app speaks it, else Azerbaijani. Never throws — storage can be unavailable (e.g. private browsing).
Future<Locale> loadInitialLocale({Locale? deviceLocale}) async {
  try {
    final saved = (await SharedPreferences.getInstance()).getString(_preferenceKey);
    if (saved != null && supportedLanguageCodes.contains(saved)) return Locale(saved);
  } catch (_) {
    // Fall through to the device language.
  }

  final device = (deviceLocale ?? PlatformDispatcher.instance.locale).languageCode;

  return Locale(supportedLanguageCodes.contains(device) ? device : defaultLanguageCode);
}

/// The language currently shown. Everything that talks to the server or draws text watches this,
/// so changing it reloads the screens in the new language.
class LocaleController extends StateNotifier<Locale> {
  LocaleController(super.initial);

  Future<void> select(String languageCode) async {
    if (!supportedLanguageCodes.contains(languageCode) || languageCode == state.languageCode) return;

    state = Locale(languageCode);
    try {
      await (await SharedPreferences.getInstance()).setString(_preferenceKey, languageCode);
    } catch (_) {
      // The choice still applies for this session.
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleController, Locale>(
  (ref) => LocaleController(const Locale(defaultLanguageCode)),
);
