import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/language_menu.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../reservations/presentation/reserve_flow.dart';
import '../availability_text.dart';
import '../distance_text.dart';
import '../location_prompt.dart';
import '../widgets/restaurant_filter_bar.dart';
import '../providers/favorites_provider.dart';
import '../providers/restaurant_filters_provider.dart';
import '../../data/restaurant_filters.dart';
import '../../../../core/location/user_location_provider.dart';
import '../../../reservations/presentation/widgets/active_reservations_banner.dart';
import '../../data/restaurant.dart';
import '../maps_launcher.dart';
import '../providers/restaurant_search_provider.dart';
import '../providers/restaurant_sort_provider.dart';
import '../providers/restaurants_provider.dart';

class RestaurantsScreen extends ConsumerStatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> {
  static const _searchDelay = Duration(milliseconds: 400);

  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(restaurantSearchProvider));
    // The first time, after the screen is up: say what location is for and ask once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(askForLocationOnce(context, ref));
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Wait for a pause in typing so each keystroke doesn't trigger a request.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDelay, () => ref.read(restaurantSearchProvider.notifier).set(value));
  }

  void _searchNow(String value) {
    _searchDebounce?.cancel();
    ref.read(restaurantSearchProvider.notifier).set(value);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchNow('');
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final sort = ref.watch(restaurantSortProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HARA'),
        actions: [
          IconButton(
            tooltip: l10n.aboutTooltip,
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push('/about'),
          ),
          IconButton(
            key: const Key('accountButton'),
            tooltip: l10n.accountTooltip,
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(ref.read(authControllerProvider) != null ? '/venue' : '/welcome'),
          ),
          const LanguageMenu(),
          TextButton.icon(
            onPressed: () => ref.read(restaurantSortProvider.notifier).toggle(),
            icon: const Icon(Icons.swap_vert),
            label: Text(sort.label),
          ),
        ],
      ),
      body: Column(
        children: [
          const ActiveReservationsBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) => TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: _searchNow,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.clearSearch,
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        ),
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
                ),
              ),
            ),
          ),
          const RestaurantFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(restaurantsProvider.future),
              child: restaurantsAsync.when(
                data: (state) => _RestaurantList(state: state, onClearSearch: _clearSearch),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => ErrorView(
                  message: l10n.couldntLoadRestaurants(apiErrorMessage(error, l10n)),
                  onRetry: () => ref.invalidate(restaurantsProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantList extends ConsumerWidget {
  const _RestaurantList({required this.state, required this.onClearSearch});

  final RestaurantsState state;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(restaurantSearchProvider);
    final filters = ref.watch(restaurantFiltersProvider);
    final l10n = AppLocalizations.of(context);

    if (state.items.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      search.isNotEmpty
                          ? l10n.noRestaurantsMatch(search)
                          : filters.favoritesOnly
                              ? l10n.noFavoritesYet
                              : filters.narrows
                                  ? l10n.noRestaurantsFilters
                                  : l10n.noRestaurantsYet,
                      key: const Key('emptyMessage'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (search.isNotEmpty)
                      TextButton(onPressed: onClearSearch, child: Text(l10n.clearSearch)),
                    if (filters.narrows)
                      TextButton(
                        key: const Key('clearFilters'),
                        onPressed: () => ref.read(restaurantFiltersProvider.notifier).clearNarrowing(),
                        child: Text(l10n.clearFilters),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.items.length + 1,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == state.items.length) return _ListFooter(state: state);

        return _RestaurantTile(restaurant: state.items[index]);
      },
    );
  }
}

class _RestaurantTile extends ConsumerWidget {
  const _RestaurantTile({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final position = ref.watch(userLocationProvider.select((location) => location.position));
    final isFavorite = ref.watch(favoritesProvider.select((favorites) => favorites.contains(restaurant.id)));
    final distance = position != null && restaurant.hasCoordinates
        ? distanceText(l10n, distanceKm(position, restaurant.latitude, restaurant.longitude))
        : null;

    final lines = [
      distance == null ? restaurant.address : '${restaurant.address} · $distance',
      if (restaurant.discountPercent > 0) l10n.discountWithCode(restaurant.discountPercent),
      // Only when it matters: a restaurant that is open needs no extra line here.
      if (!restaurant.availability.acceptingRequests) availabilityText(l10n, restaurant.availability),
    ];

    return ListTile(
      leading: IconButton(
        key: Key('fav-${restaurant.id}'),
        tooltip: isFavorite ? l10n.removeFavorite : l10n.addFavorite,
        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Theme.of(context).colorScheme.error : null),
        onPressed: () => ref.read(favoritesProvider.notifier).toggle(restaurant.id),
      ),
      title: Text(restaurant.name),
      subtitle: Text(lines.join('\n'), key: Key('tile-info-${restaurant.id}')),
      isThreeLine: lines.length > 1,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.openInGoogleMaps,
            icon: const Icon(Icons.map_outlined),
            onPressed: () => openInGoogleMaps(restaurant),
          ),
          FilledButton.tonal(
            // Closed (or closing so soon it takes no more requests): the server would refuse it anyway.
            onPressed: restaurant.availability.acceptingRequests ? () => startReservation(context, restaurant) : null,
            child: Text(l10n.reserve),
          ),
        ],
      ),
      onTap: () => context.push('/restaurants/${restaurant.id}'),
    );
  }
}

/// The last row: the next page loading in (the list asks for it as soon as this row scrolls into
/// view), a retry if that failed, or, once everything is loaded, the "add your restaurant" entry.
class _ListFooter extends ConsumerWidget {
  const _ListFooter({required this.state});

  final RestaurantsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    if (state.hasMore && state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              l10n.couldntLoadMoreRestaurants(apiErrorMessage(state.loadMoreError!, l10n)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.read(restaurantsProvider.notifier).retryLoadMore(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (state.hasMore) {
      if (!state.isLoadingMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(restaurantsProvider.notifier).loadMore();
        });
      }

      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    // Everything is loaded: nothing more to show below the last restaurant.
    return const SizedBox.shrink();
  }
}
