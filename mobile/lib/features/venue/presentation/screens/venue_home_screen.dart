import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/push/push_registrar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/language_menu.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/venue_me.dart';
import '../../data/venue_models.dart';
import '../providers/venue_providers.dart';
import '../widgets/code_confirm_tab.dart';
import 'terms_gate_screen.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/requests_tab.dart';
import '../widgets/reservations_tab.dart';
import '../widgets/restaurant_tab.dart';
import '../widgets/stats_tab.dart';
import '../widgets/team_tab.dart';

/// The owner's and waiters' home. What it shows depends on where the account stands: waiting for
/// approval, declined, or approved for a restaurant — which opens the working screens.
class VenueHomeScreen extends ConsumerWidget {
  const VenueHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(venueMeProvider);
    final me = meAsync.valueOrNull;

    // New or changed terms come first: nothing else works until they are accepted.
    if (me != null && me.pendingTerms.isNotEmpty) {
      return TermsGateScreen(pending: me.pendingTerms, actions: const [_AccountActions()]);
    }

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
        PopupMenuButton<String>(
          key: const Key('accountMenu'),
          tooltip: l10n.accountMenu,
          onSelected: (choice) async {
            if (choice == 'privacy') {
              context.push('/privacy');
              return;
            }

            final deleted = await showDialog<bool>(context: context, builder: (_) => const DeleteAccountDialog());
            if (deleted == true) unawaited(ref.read(pushRegistrarProvider).unregisterVenue());
            if (deleted == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
              context.go('/');
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'privacy', child: Text(l10n.privacyPolicy)),
            PopupMenuItem(key: const Key('deleteAccountItem'), value: 'delete', child: Text(l10n.deleteAccount)),
          ],
        ),
        IconButton(
          key: const Key('signOut'),
          tooltip: l10n.signOut,
          icon: const Icon(Icons.logout),
          onPressed: () async {
            // While still signed in, so the server knows whose notifications to stop on this phone.
            await ref.read(pushRegistrarProvider).unregisterVenue();
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
class _ApprovedVenue extends ConsumerStatefulWidget {
  const _ApprovedVenue({required this.me, required this.restaurant});

  final VenueMe me;
  final VenueRestaurant restaurant;

  @override
  ConsumerState<_ApprovedVenue> createState() => _ApprovedVenueState();
}

class _ApprovedVenueState extends ConsumerState<_ApprovedVenue> {
  /// How often the list of waiting requests is fetched again while these screens are open.
  static const _requestsCheck = Duration(seconds: 10);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // This phone is told about new requests even when the app is closed.
    unawaited(ref.read(pushRegistrarProvider).registerVenue());
    _timer = Timer.periodic(_requestsCheck, (_) {
      ref.invalidate(venueReservationsProvider(ReservationFilter.pending));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = widget.me;

    // Notifications are written in the app's language, so the server is told when it changes.
    ref.listen(localeProvider, (previous, next) => unawaited(ref.read(pushRegistrarProvider).registerVenue()));

    // A new request: a sound and a buzz, since the waiter may be looking elsewhere.
    ref.listen<AsyncValue<List<VenueReservation>>>(venueReservationsProvider(ReservationFilter.pending), (previous, next) {
      final before = previous?.valueOrNull?.length;
      final now = next.valueOrNull?.length;
      if (before != null && now != null && now > before) {
        unawaited(SystemSound.play(SystemSoundType.alert));
        unawaited(HapticFeedback.heavyImpact());
      }
    });
    final waiting = ref.watch(venueReservationsProvider(ReservationFilter.pending)).valueOrNull?.length ?? 0;

    final tabs = <({String label, IconData icon, int badge, Widget body})>[
      (label: l10n.tabRequests, icon: Icons.notifications_active_outlined, badge: waiting, body: const RequestsTab()),
      (label: l10n.tabConfirmCode, icon: Icons.qr_code_2, badge: 0, body: const CodeConfirmTab()),
      (label: l10n.tabReservations, icon: Icons.event_seat_outlined, badge: 0, body: const ReservationsTab()),
      (label: l10n.tabStats, icon: Icons.bar_chart, badge: 0, body: const StatsTab()),
      if (me.isOwner) (label: l10n.tabTeam, icon: Icons.groups_outlined, badge: 0, body: const TeamTab()),
      if (me.isOwner) (label: l10n.tabRestaurant, icon: Icons.storefront_outlined, badge: 0, body: RestaurantTab(restaurant: widget.restaurant)),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.restaurant.name),
          actions: const [_AccountActions()],
          bottom: TabBar(
            isScrollable: tabs.length > 3,
            tabs: [
              for (final tab in tabs)
                Tab(
                  text: tab.label,
                  icon: Badge(
                    key: tab.badge > 0 ? Key('badge-${tab.label}') : null,
                    isLabelVisible: tab.badge > 0,
                    label: Text('${tab.badge}'),
                    child: Icon(tab.icon),
                  ),
                ),
            ],
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
