import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/restaurant_filters.dart';
import '../location_prompt.dart';
import '../providers/restaurant_filters_provider.dart';

/// A row of chips under the search box: open now, nearest, favourites, and one per cuisine.
class RestaurantFilterBar extends ConsumerWidget {
  const RestaurantFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filters = ref.watch(restaurantFiltersProvider);
    final notifier = ref.read(restaurantFiltersProvider.notifier);
    final locationOffered = ref.watch(locationServiceProvider).isSupported;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _chip(
            key: const Key('chip-open'),
            label: l10n.filterOpenNow,
            icon: Icons.schedule,
            selected: filters.openNow,
            onSelected: (_) => notifier.toggleOpenNow(),
          ),
          if (locationOffered)
            _chip(
              key: const Key('chip-nearest'),
              label: l10n.filterNearest,
              icon: Icons.near_me_outlined,
              selected: filters.nearest,
              onSelected: (selected) async {
                if (!selected) {
                  notifier.setNearest(false);
                  return;
                }
                if (await ensureLocationForNearest(context, ref)) notifier.setNearest(true);
              },
            ),
          _chip(
            key: const Key('chip-favorites'),
            label: l10n.filterFavorites,
            icon: Icons.favorite_border,
            selected: filters.favoritesOnly,
            onSelected: (_) => notifier.toggleFavorites(),
          ),
          for (final code in cuisineCodes)
            _chip(
              key: Key('chip-cuisine-$code'),
              label: l10n.cuisineName(code),
              selected: filters.cuisine == code,
              onSelected: (_) => notifier.toggleCuisine(code),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required Key key,
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    IconData? icon,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: FilterChip(
          key: key,
          avatar: icon == null ? null : Icon(icon, size: 18),
          label: Text(label),
          selected: selected,
          onSelected: onSelected,
        ),
      );
}
