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
                      search.isEmpty ? l10n.noRestaurantsYet : l10n.noRestaurantsMatch(search),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (search.isNotEmpty)
                      TextButton(onPressed: onClearSearch, child: Text(l10n.clearSearch)),
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

class _RestaurantTile extends StatelessWidget {
  const _RestaurantTile({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      title: Text(restaurant.name),
      subtitle: Text(
        restaurant.discountPercent > 0
            ? '${restaurant.address}\n${l10n.discountWithCode(restaurant.discountPercent)}'
            : restaurant.address,
      ),
      isThreeLine: restaurant.discountPercent > 0,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.openInGoogleMaps,
            icon: const Icon(Icons.map_outlined),
            onPressed: () => openInGoogleMaps(restaurant),
          ),
          FilledButton.tonal(
            onPressed: () => startReservation(context, restaurant),
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
