import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/restaurants/presentation/providers/restaurant_filters_provider.dart';
import '../../l10n/app_localizations.dart';

/// The three places of the customer's app, in the bar at the bottom: discover places, the ones marked with a heart, and "more"
/// (about, contact, appearance, the texts, and the way in for restaurants).
enum HomeTab { discover, favorites, more }

class HaraBottomNav extends ConsumerWidget {
  const HaraBottomNav({required this.current, super.key});

  final HomeTab current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filters = ref.read(restaurantFiltersProvider.notifier);

    void open(HomeTab tab) {
      if (tab == current) return;

      switch (tab) {
        case HomeTab.discover:
          filters.setFavorites(false);
          context.go('/');
        case HomeTab.favorites:
          filters.setFavorites(true);
          context.go('/');
        case HomeTab.more:
          context.go('/about');
      }
    }

    return NavigationBar(
      selectedIndex: current.index,
      onDestinationSelected: (index) => open(HomeTab.values[index]),
      destinations: [
        NavigationDestination(
          key: const Key('nav-discover'),
          icon: const Icon(Icons.explore_outlined),
          selectedIcon: const Icon(Icons.explore),
          label: l10n.navDiscover,
        ),
        NavigationDestination(
          key: const Key('nav-favorites'),
          icon: const Icon(Icons.favorite_border),
          selectedIcon: const Icon(Icons.favorite),
          label: l10n.navFavorites,
        ),
        NavigationDestination(
          key: const Key('nav-more'),
          icon: const Icon(Icons.more_horiz),
          selectedIcon: const Icon(Icons.more_horiz),
          label: l10n.navMore,
        ),
      ],
    );
  }
}
