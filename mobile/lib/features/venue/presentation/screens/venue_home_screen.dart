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
import '../widgets/code_confirm_tab.dart';
import '../widgets/reservations_tab.dart';
import '../widgets/restaurant_tab.dart';
import '../widgets/team_tab.dart';

/// The owner's and waiters' home. What it shows depends on where the account stands: waiting for
/// approval, declined, or approved for a restaurant — which opens the working screens.
class VenueHomeScreen extends ConsumerWidget {
  const VenueHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(venueMeProvider);
    final me = meAsync.valueOrNull;

    if (me != null && me.status == VenueStatus.approved && me.restaurant != null) {
      return _ApprovedVenue(me: me, restaurant: me.restaurant!);
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.venueTitle), actions: const [_AccountActions()]),
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

class _AccountActions extends ConsumerWidget {
  const _AccountActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LanguageMenu(),
        IconButton(
          key: const Key('browseRestaurants'),
          tooltip: l10n.browseAsCustomer,
          icon: const Icon(Icons.restaurant_menu),
          onPressed: () => context.go('/'),
        ),
        IconButton(
          key: const Key('signOut'),
          tooltip: l10n.signOut,
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).signOut();
            if (context.mounted) context.go('/');
          },
        ),
      ],
    );
  }
}

/// The working screens: confirm a customer's code and see the reservations; the owner also manages the
/// team and asks HARA for changes.
class _ApprovedVenue extends StatelessWidget {
  const _ApprovedVenue({required this.me, required this.restaurant});

  final VenueMe me;
  final VenueRestaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final tabs = <({String label, IconData icon, Widget body})>[
      (label: l10n.tabConfirmCode, icon: Icons.qr_code_2, body: const CodeConfirmTab()),
      (label: l10n.tabReservations, icon: Icons.event_seat_outlined, body: const ReservationsTab()),
      if (me.isOwner) (label: l10n.tabTeam, icon: Icons.groups_outlined, body: const TeamTab()),
      if (me.isOwner) (label: l10n.tabRestaurant, icon: Icons.storefront_outlined, body: RestaurantTab(restaurant: restaurant)),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(restaurant.name),
          actions: const [_AccountActions()],
          bottom: TabBar(
            isScrollable: tabs.length > 3,
            tabs: [for (final tab in tabs) Tab(text: tab.label, icon: Icon(tab.icon))],
          ),
        ),
        body: TabBarView(children: [for (final tab in tabs) tab.body]),
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
      // Approved but without a restaurant should not happen; treat like nothing on record.
      VenueStatus.approved || VenueStatus.none => _Notice(
          icon: Icons.link_off,
          title: l10n.venueTitle,
          text: l10n.noVenueText,
          onCheckAgain: () => ref.invalidate(venueMeProvider),
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
    };
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.text, required this.onCheckAgain});

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onCheckAgain;

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
                    const SizedBox(height: 8),
                    Text(text, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton.tonal(onPressed: onCheckAgain, child: Text(l10n.checkAgain)),
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
