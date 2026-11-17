import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/customer/customer_controller.dart';
import '../../../l10n/app_localizations.dart';

/// Signs the customer in with Google (and out, and deletes the account). Hidden where Google sign-in is not offered.
Future<bool> signInCustomer(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  try {
    return await ref.read(customerControllerProvider.notifier).signIn();
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.signInFailed)));
    return false;
  }
}

class CustomerAccountCard extends ConsumerWidget {
  const CustomerAccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(customerControllerProvider.notifier);
    final session = ref.watch(customerControllerProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (!controller.canSignIn && session == null) return const SizedBox.shrink();

    if (session == null) {
      return Card(
        key: const Key('customerAccountCard'),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.customerSignInHint, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('signInWithGoogle'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => signInCustomer(context, ref),
                icon: const Icon(Icons.account_circle_outlined),
                label: Text(l10n.signInWithGoogle),
              ),
            ],
          ),
        ),
      );
    }

    final photo = session.photoUrl;

    return Card(
      key: const Key('customerAccountCard'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: photo == null ? null : NetworkImage(photo),
              child: photo == null ? const Icon(Icons.person_outline) : null,
            ),
            title: Text(session.name ?? l10n.anonymousReviewer, key: const Key('customerName')),
            subtitle: Text(l10n.signedInAs),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                TextButton(
                  key: const Key('customerSignOut'),
                  onPressed: () => controller.signOut(),
                  child: Text(l10n.signOut),
                ),
                const Spacer(),
                TextButton(
                  key: const Key('customerDelete'),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  onPressed: () => _confirmDelete(context, ref),
                  child: Text(l10n.deleteAccount),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.customerDeleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            key: const Key('customerDeleteConfirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(customerControllerProvider.notifier).deleteAccount();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.signInFailed)));
    }
  }
}
