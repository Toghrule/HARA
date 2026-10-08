import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/language_menu.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/venue_me.dart';
import '../providers/venue_providers.dart';

/// The owner's and waiters' home. What it shows depends on where the account stands: waiting for
/// approval, declined, or approved for a restaurant.
class VenueHomeScreen extends ConsumerWidget {
  const VenueHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final meAsync = ref.watch(venueMeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(meAsync.valueOrNull?.restaurant?.name ?? l10n.venueTitle),
        actions: [
          const LanguageMenu(),
          IconButton(
            tooltip: l10n.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: meAsync.when(
        data: (me) => RefreshIndicator(
          onRefresh: () => ref.refresh(venueMeProvider.future),
          child: _Status(me: me),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorView(
          message: apiErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(venueMeProvider),
        ),
      ),
    );
  }
}

class _Status extends ConsumerWidget {
  const _Status({required this.me});

  final VenueMe me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return switch (me.status) {
      VenueStatus.approved => _Notice(
          icon: Icons.check_circle_outline,
          title: me.restaurant?.name ?? l10n.venueTitle,
          text: me.restaurant?.address ?? '',
        ),
      VenueStatus.pending => _Notice(
          icon: Icons.hourglass_top,
          title: l10n.pendingOwnerTitle,
          text: me.isOwner ? l10n.pendingOwnerText : l10n.pendingStaffText,
          onCheckAgain: () => ref.invalidate(venueMeProvider),
        ),
      VenueStatus.rejected => _Notice(
          icon: Icons.highlight_off,
          title: l10n.rejectedTitle,
          text: [
            l10n.rejectedText,
            if (me.note != null && me.note!.trim().isNotEmpty) l10n.rejectedReason(me.note!.trim()),
          ].join('\n\n'),
          onCheckAgain: () => ref.invalidate(venueMeProvider),
        ),
      VenueStatus.none => _Notice(
          icon: Icons.link_off,
          title: l10n.venueTitle,
          text: l10n.noVenueText,
          onCheckAgain: () => ref.invalidate(venueMeProvider),
        ),
    };
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.text, this.onCheckAgain});

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback? onCheckAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 72, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(text, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                    ],
                    if (onCheckAgain != null) ...[
                      const SizedBox(height: 24),
                      FilledButton.tonal(onPressed: onCheckAgain, child: Text(l10n.checkAgain)),
                    ],
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => context.go('/'), child: Text(l10n.browseAsCustomer)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
