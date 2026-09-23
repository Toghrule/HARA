import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/restaurant.dart';
import '../providers/restaurant_sort_provider.dart';
import '../providers/restaurants_provider.dart';

class RestaurantsScreen extends ConsumerWidget {
  const RestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final sort = ref.watch(restaurantSortProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HARA'),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(restaurantSortProvider.notifier).toggle(),
            icon: const Icon(Icons.swap_vert),
            label: Text(sort.label),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(restaurantsProvider.future),
        child: restaurantsAsync.when(
          data: (restaurants) => _RestaurantList(restaurants: restaurants),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorView(
            message: '$error',
            onRetry: () => ref.invalidate(restaurantsProvider),
          ),
        ),
      ),
    );
  }
}

class _RestaurantList extends StatelessWidget {
  const _RestaurantList({required this.restaurants});

  final List<Restaurant> restaurants;

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: const Center(child: Text('No restaurants yet.')),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: restaurants.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        return ListTile(
          title: Text(restaurant.name),
          subtitle: Text(restaurant.address),
          trailing: const Icon(Icons.map_outlined),
          onTap: () => _openInGoogleMaps(restaurant),
        );
      },
    );
  }

  Future<void> _openInGoogleMaps(Restaurant restaurant) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${restaurant.latitude},${restaurant.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Couldn\'t load restaurants.\n$message',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
