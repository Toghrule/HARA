import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/widgets/language_menu.dart';
import '../../l10n/app_localizations.dart';
import 'privacy_policy.dart';

/// The privacy policy, in the language the app is showing.
class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sections = privacyPolicyFor(ref.watch(localeProvider).languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy), actions: const [LanguageMenu()]),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(privacyPolicyUpdated, style: theme.textTheme.bodySmall),
                for (final section in sections) ...[
                  const SizedBox(height: 24),
                  Text(section.title, style: theme.textTheme.titleMedium),
                  for (final paragraph in section.paragraphs) ...[
                    const SizedBox(height: 8),
                    Text(paragraph, style: theme.textTheme.bodyMedium),
                  ],
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small link to the privacy policy, for the bottom of sign-in and registration screens.
class PrivacyPolicyLink extends StatelessWidget {
  const PrivacyPolicyLink({super.key});

  @override
  Widget build(BuildContext context) => TextButton(
        key: const Key('privacyPolicyLink'),
        onPressed: () => context.push('/privacy'),
        child: Text(AppLocalizations.of(context).privacyPolicy),
      );
}
