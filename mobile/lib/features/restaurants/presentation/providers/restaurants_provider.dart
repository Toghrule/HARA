import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/restaurant.dart';
import '../../data/restaurants_repository.dart';
import 'restaurant_search_provider.dart';
import 'restaurant_sort_provider.dart';

class RestaurantsState {
  const RestaurantsState({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<Restaurant> items;

  /// Whether the server may have more pages after the ones loaded so far.
  final bool hasMore;
  final bool isLoadingMore;

  /// Set when fetching the next page failed; the list keeps what it already has.
  final Object? loadMoreError;

  RestaurantsState loadingMore() => RestaurantsState(items: items, hasMore: hasMore, isLoadingMore: true);

  RestaurantsState failedToLoadMore(Object error) =>
      RestaurantsState(items: items, hasMore: hasMore, loadMoreError: error);

  /// Adds the next page, leaving out restaurants already in the list. Pages can overlap when a
  /// restaurant is added or removed between requests, and a server that doesn't know about paging
  /// answers every request with the full list; a page with nothing new means there is nothing more.
  RestaurantsState withNextPage(List<Restaurant> next, {required bool hasMore}) {
    final known = items.map((restaurant) => restaurant.id).toSet();
    final fresh = next.where((restaurant) => !known.contains(restaurant.id)).toList();

    return RestaurantsState(items: [...items, ...fresh], hasMore: hasMore && fresh.isNotEmpty);
  }

  RestaurantsState withoutError() => RestaurantsState(items: items, hasMore: hasMore);
}

/// The restaurant list for the current sort and search, loaded one page at a time.
/// Changing the sort or the search starts over from the first page.
class RestaurantsController extends AutoDisposeAsyncNotifier<RestaurantsState> {
  static const pageSize = 20;

  int _page = 1;

  // Bumped whenever the list is rebuilt or disposed, so a page request that was still in flight
  // for the old sort/search can't be added to the new list.
  int _generation = 0;

  @override
  Future<RestaurantsState> build() async {
    final sort = ref.watch(restaurantSortProvider);
    final search = ref.watch(restaurantSearchProvider);
    final repository = ref.watch(restaurantsRepositoryProvider);

    _generation++;
    ref.onDispose(() => _generation++);
    _page = 1;

    final items = await repository.getRestaurants(sort: sort, search: search, pageSize: pageSize);

    return RestaurantsState(items: items, hasMore: items.length >= pageSize);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore || current.loadMoreError != null) return;

    final generation = _generation;
    state = AsyncData(current.loadingMore());

    try {
      final next = await ref.read(restaurantsRepositoryProvider).getRestaurants(
            sort: ref.read(restaurantSortProvider),
            search: ref.read(restaurantSearchProvider),
            page: _page + 1,
            pageSize: pageSize,
          );
      if (generation != _generation) return;

      _page++;
      state = AsyncData(current.withNextPage(next, hasMore: next.length >= pageSize));
    } catch (error) {
      if (generation != _generation) return;

      state = AsyncData(current.failedToLoadMore(error));
    }
  }

  Future<void> retryLoadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.withoutError());
    await loadMore();
  }
}

final restaurantsProvider = AsyncNotifierProvider.autoDispose<RestaurantsController, RestaurantsState>(
  RestaurantsController.new,
);
