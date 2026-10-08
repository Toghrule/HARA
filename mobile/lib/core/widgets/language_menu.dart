import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../l10n/locale_provider.dart';

/// Each language is named in itself, so someone who can't read the current one can still find theirs.
const _languageNames = {
  'az': 'Azərbaycanca',
  'ru': 'Русский',
  'en': 'English',
};

/// App-bar button that lets the user switch the app's language.
class LanguageMenu extends ConsumerWidget {
  const LanguageMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider).languageCode;

    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context).language,
      icon: const Icon(Icons.language),
      initialValue: current,
      onSelected: (code) => ref.read(localeProvider.notifier).select(code),
      itemBuilder: (context) => [
        for (final code in supportedLanguageCodes)
          CheckedPopupMenuItem<String>(
            value: code,
            checked: code == current,
            child: Text(_languageNames[code] ?? code),
          ),
      ],
    );
  }
}
