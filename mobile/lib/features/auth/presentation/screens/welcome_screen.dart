import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/hara_logo.dart';
import '../../../../core/widgets/language_menu.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../legal/legal_text_screen.dart';
import '../../../legal/privacy_policy_screen.dart';
import '../../data/customer_choice.dart';

/// The registration screen: one screen, two parts. Customers just continue (no account); restaurant
/// owners and waiters sign in or sign up.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const HaraLogo(), actions: const [LanguageMenu()]),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: ColoredBox(
                    color: Colors.black,
                    child: Image.asset('assets/logo/logo.png', key: const Key('welcomeLogo'), height: 180, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 20),
                Text(l10n.welcomeTitle, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(l10n.welcomeSubtitle, style: textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                _Section(
                  icon: Icons.restaurant_menu,
                  title: l10n.customerSectionTitle,
                  text: l10n.customerSectionText,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      key: const Key('continueAsCustomer'),
                      onPressed: () async {
                        await ref.read(customerChoiceProvider.notifier).choose();
                        if (context.mounted) context.go('/');
                      },
                      child: Text(l10n.continueAsCustomer),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  icon: Icons.storefront_outlined,
                  title: l10n.ownerSectionTitle,
                  text: l10n.ownerSectionText,
                  children: [
                    FilledButton.tonal(
                      key: const Key('signIn'),
                      onPressed: () => context.push('/login'),
                      child: Text(l10n.signIn),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const Key('registerAsOwner'),
                      onPressed: () => context.push('/register-owner'),
                      child: Text(l10n.registerAsOwner),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      key: const Key('registerAsStaff'),
                      onPressed: () => context.push('/register-staff'),
                      child: Text(l10n.registerAsStaff),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Center(child: PrivacyPolicyLink()),
                const Center(child: TermsLink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.text, required this.children});

  final IconData icon;
  final String title;
  final String text;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 12),
            Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
