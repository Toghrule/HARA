import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/hara_logo.dart';
import '../../../../core/widgets/language_menu.dart';
import '../../../../core/widgets/hara_bottom_nav.dart';
import '../../../../core/widgets/hara_ui.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/feature_flags.dart';
import '../../../discounts/data/discounts_repository.dart';
import '../../../discounts/presentation/discount_flow.dart';
import '../../../reservations/presentation/reserve_flow.dart';
import '../availability_text.dart';
import '../location_prompt.dart';
import '../widgets/restaurant_filter_bar.dart';
import '../../../advertisements/data/advertisement.dart';
import '../../../advertisements/presentation/ad_banner.dart';
import '../../data/restaurant_filters.dart';
import '../providers/areas_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/featured_provider.dart';
import '../providers/restaurant_filters_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../reservations/presentation/widgets/active_reservations_banner.dart';
import '../../data/restaurant.dart';
import '../maps_launcher.dart';
import '../providers/restaurant_search_provider.dart';
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const HaraLogo(),
        actions: [
          IconButton(
            key: const Key('accountButton'),
            tooltip: l10n.accountTooltip,
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(ref.read(authControllerProvider) != null ? '/venue' : '/welcome'),
          ),
          const LanguageMenu(),
        ],
      ),
      bottomNavigationBar: HaraBottomNav(current: ref.watch(restaurantFiltersProvider.select((f) => f.favoritesOnly)) ? HomeTab.favorites : HomeTab.discover),
      body: Column(
        children: [
          if (FeatureFlags.reservationsEnabled) const ActiveReservationsBanner(),
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
                  filled: true,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(28)), borderSide: BorderSide.none),
                  enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(28)), borderSide: BorderSide.none),
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
                    const IconBadge(icon: Icons.restaurant_menu),
                    const SizedBox(height: 16),
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

    // At the very top, when nothing narrows the list: this week's picks (paid places, wherever the customer is), then the places that
    // give a discount, each in a row to swipe through.
    final browsing = search.isEmpty && !filters.narrows;
    final featured = browsing ? ref.watch(featuredRestaurantsProvider).valueOrNull ?? const <Restaurant>[] : const <Restaurant>[];
    final ads = browsing ? ref.watch(advertisementsProvider).valueOrNull ?? const <Advertisement>[] : const <Advertisement>[];
    final discounted = state.items.where((restaurant) => restaurant.discountPercent > 0).take(10).toList();
    final showStrip = discounted.length >= 3 && browsing;
    // The area chips stay while an area is chosen (so it can be unchosen), but not while anything else narrows the list.
    final onlyArea = search.isEmpty && !filters.openNow && !filters.favoritesOnly && filters.cuisine == null;
    final areas = onlyArea ? ref.watch(areasProvider).valueOrNull ?? const <AreaCount>[] : const <AreaCount>[];
    final headers = [
      if (featured.isNotEmpty) _FeaturedStrip(restaurants: featured),
      if (ads.isNotEmpty) AdBanner(ads: ads),
      if (areas.isNotEmpty) _AreaSection(areas: areas, selected: filters.district),
      if (showStrip) _DiscountStrip(restaurants: discounted),
    ];
    final offset = headers.length;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: state.items.length + 1 + offset,
      itemBuilder: (context, index) {
        if (index < offset) return headers[index];
        if (index == state.items.length + offset) return _ListFooter(state: state);

        return _RestaurantTile(restaurant: state.items[index - offset]);
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
    final isFavorite = ref.watch(favoritesProvider.select((favorites) => favorites.contains(restaurant.id)));
    final cuisines = restaurant.cuisines.take(2).map(l10n.cuisineName).join(', ');
    final lines = [
      if (cuisines.isNotEmpty) cuisines,
      restaurant.address,
      if (restaurant.discountPercent > 0) FeatureFlags.reservationsEnabled ? l10n.discountWithCode(restaurant.discountPercent) : l10n.discountOffer(restaurant.discountPercent),
      // Only when it matters: a restaurant that is open needs no extra line here.
      if (!restaurant.availability.acceptingRequests) availabilityText(l10n, restaurant.availability),
    ];

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cover = restaurant.photoUris.isEmpty ? null : restaurant.photoUris.first;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(child: Icon(Icons.restaurant, size: 40, color: scheme.onSurfaceVariant)),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        key: Key('restaurant-${restaurant.id}'),
        onTap: () => context.push('/restaurants/${restaurant.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (cover == null)
                    placeholder
                  else
                    Image.network(
                      cover.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => placeholder,
                      loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
                    ),
                  if (restaurant.discountPercent > 0)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        key: Key('discount-${restaurant.id}'),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(color: scheme.secondary, borderRadius: BorderRadius.circular(14)),
                        child: Text('-${restaurant.discountPercent}%', style: TextStyle(color: scheme.onSecondary, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                        key: Key('fav-${restaurant.id}'),
                        tooltip: isFavorite ? l10n.removeFavorite : l10n.addFavorite,
                        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.redAccent : Colors.white),
                        onPressed: () => ref.read(favoritesProvider.notifier).toggle(restaurant.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (restaurant.ratingAverage != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.star_rounded, size: 18, color: AppTheme.gold),
                        const SizedBox(width: 2),
                        Text(restaurant.ratingAverage!.toStringAsFixed(1), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text(' (${restaurant.ratingCount})', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lines.join('\n'),
                    key: Key('tile-info-${restaurant.id}'),
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: l10n.openInGoogleMaps,
                        icon: const Icon(Icons.map_outlined),
                        onPressed: () {
                          unawaited(ref.read(discountsRepositoryProvider).recordEvent(restaurant.id, RestaurantEvent.directions));
                          unawaited(openInGoogleMaps(restaurant));
                        },
                      ),
                      // The button takes what the map icon leaves, and its words are cut rather than overflow (a long language, a narrow phone).
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Without reservations a restaurant that gives a discount offers the code instead.
                              if (!FeatureFlags.reservationsEnabled && restaurant.discountPercent > 0)
                                Flexible(
                                  child: FilledButton(
                                    key: Key('getDiscount-${restaurant.id}'),
                                    onPressed: () => getDiscount(context, ref, restaurant),
                                    child: Text(l10n.getDiscount, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              if (FeatureFlags.reservationsEnabled)
                                Flexible(
                                  child: FilledButton(
                                    // Closed (or closing so soon it takes no more requests): the server would refuse it anyway.
                                    onPressed: restaurant.availability.acceptingRequests ? () => startReservation(context, restaurant) : null,
                                    child: Text(l10n.reserve, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Ərazi": the areas of Baku that have restaurants, as chips to pick one from.
class _AreaSection extends ConsumerWidget {
  const _AreaSection({required this.areas, required this.selected});

  final List<AreaCount> areas;
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      key: const Key('areaSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(l10n.areaSection, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: areas.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final area = areas[index];

              return FilterChip(
                key: Key('area-${area.code}'),
                label: Text(l10n.areaName(area.code)),
                selected: selected == area.code,
                showCheckmark: false,
                onSelected: (_) => ref.read(restaurantFiltersProvider.notifier).toggleDistrict(area.code),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// "This week's picks": the places that took a turn at the top, as big cards in a row.
class _FeaturedStrip extends StatelessWidget {
  const _FeaturedStrip({required this.restaurants});

  final List<Restaurant> restaurants;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      key: const Key('featuredStrip'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              Icon(Icons.workspace_premium, color: AppTheme.gold, size: 24),
              const SizedBox(width: 6),
              Expanded(child: Text(l10n.featuredSection, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
            ],
          ),
        ),
        SizedBox(
          height: 208,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: restaurants.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              final cover = restaurant.photoUris.isEmpty ? null : restaurant.photoUris.first;
              final placeholder = ColoredBox(color: scheme.surfaceContainerHigh, child: Icon(Icons.restaurant, size: 36, color: scheme.onSurfaceVariant));
              final cuisines = restaurant.cuisines.take(2).map(l10n.cuisineName).join(', ');

              return SizedBox(
                width: 270,
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppTheme.gold, width: 1.5),
                  ),
                  child: InkWell(
                    key: Key('featured-${restaurant.id}'),
                    onTap: () => context.push('/restaurants/${restaurant.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (cover == null)
                                placeholder
                              else
                                Image.network(cover.toString(), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => placeholder),
                              Positioned(
                                left: 10,
                                top: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.workspace_premium, size: 16, color: Color(0xFF2A1B00)),
                                      const SizedBox(width: 4),
                                      Text(l10n.featuredBadge, style: const TextStyle(color: Color(0xFF2A1B00), fontWeight: FontWeight.w800, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              if (restaurant.discountPercent > 0)
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(color: scheme.secondary, borderRadius: BorderRadius.circular(12)),
                                    child: Text('-${restaurant.discountPercent}%', style: TextStyle(color: scheme.onSecondary, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(restaurant.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                                  if (restaurant.ratingAverage != null) ...[
                                    Icon(Icons.star_rounded, size: 18, color: AppTheme.gold),
                                    Text(restaurant.ratingAverage!.toStringAsFixed(1), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  ],
                                ],
                              ),
                              Text(
                                [if (cuisines.isNotEmpty) cuisines, restaurant.address].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// "Discounts": the places that give one, as small cards in a row.
class _DiscountStrip extends StatelessWidget {
  const _DiscountStrip({required this.restaurants});

  final List<Restaurant> restaurants;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      key: const Key('discountStrip'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(l10n.discountsSection, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: restaurants.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              final cover = restaurant.photoUris.isEmpty ? null : restaurant.photoUris.first;
              final placeholder = ColoredBox(color: scheme.surfaceContainerHigh, child: Icon(Icons.restaurant, color: scheme.onSurfaceVariant));

              return SizedBox(
                width: 150,
                child: InkWell(
                  key: Key('strip-${restaurant.id}'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/restaurants/${restaurant.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 120,
                          width: 150,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (cover == null)
                                placeholder
                              else
                                Image.network(cover.toString(), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => placeholder),
                              Positioned(
                                left: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: scheme.secondary, borderRadius: BorderRadius.circular(12)),
                                  child: Text('-${restaurant.discountPercent}%', style: TextStyle(color: scheme.onSecondary, fontWeight: FontWeight.w800, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(restaurant.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
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
