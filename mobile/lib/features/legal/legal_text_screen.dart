import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/widgets/language_menu.dart';
import '../../l10n/app_localizations.dart';
import 'legal_documents.dart';

/// The terms of use or the restaurant agreement, in the language the app is showing.
class LegalTextScreen extends ConsumerWidget {
  const LegalTextScreen({required this.text, super.key});

  final LegalText text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sections = legalTextFor(text, ref.watch(localeProvider).languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(text == LegalText.terms ? l10n.termsOfUse : l10n.venueAgreementTitle),
        actions: const [LanguageMenu()],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(legalTextsUpdated, style: theme.textTheme.bodySmall),
                for (final section in sections) ...[
                  const SizedBox(height: 24),
                  Text(section.title, key: const Key('legalSection'), style: theme.textTheme.titleMedium),
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

/// A small link to the terms of use, for the bottom of the first screens.
class TermsLink extends StatelessWidget {
  const TermsLink({super.key});

  @override
  Widget build(BuildContext context) => TextButton(
        key: const Key('termsLink'),
        onPressed: () => context.push('/terms'),
        child: Text(AppLocalizations.of(context).termsOfUse),
      );
}

/// The route of each text.
String legalTextRoute(LegalText text) => text == LegalText.terms ? '/terms' : '/restaurant-agreement';
