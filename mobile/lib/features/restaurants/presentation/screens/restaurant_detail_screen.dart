import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_error.dart';
import '../../../reservations/presentation/reserve_flow.dart';
import '../../data/restaurant.dart';
import '../maps_launcher.dart';
import '../providers/restaurant_provider.dart';

class RestaurantDetailScreen extends ConsumerWidget {
  const RestaurantDetailScreen({required this.restaurantId, super.key});

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantProvider(restaurantId));
    final restaurant = restaurantAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(restaurant?.name ?? 'Restaurant')),
      body: restaurantAsync.when(
        data: (restaurant) => _Details(restaurant: restaurant),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          message: error is DioException && error.response?.statusCode == 404
              ? 'This restaurant is no longer available.'
              : apiErrorMessage(error),
          onRetry: () => ref.invalidate(restaurantProvider(restaurantId)),
        ),
      ),
      bottomNavigationBar: restaurant == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: () => startReservation(context, restaurant),
                  icon: const Icon(Icons.event_seat),
                  label: const Text('Reserve a table'),
                ),
              ),
            ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = restaurant.description?.trim();
    final phone = restaurant.phoneNumber?.trim();

    return ListView(
      children: [
        _CoverImage(imageUri: restaurant.imageUri),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(restaurant.name, style: theme.textTheme.headlineSmall),
              if (restaurant.discountPercent > 0) ...[
                const SizedBox(height: 12),
                Chip(
                  avatar: const Icon(Icons.local_offer_outlined, size: 18),
                  label: Text('${restaurant.discountPercent}% off with a reservation code'),
                ),
              ],
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(restaurant.address),
          trailing: const Icon(Icons.map_outlined),
          onTap: () => openInGoogleMaps(restaurant),
        ),
        if (phone != null && phone.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: Text(phone),
            onTap: () => launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', ''))),
          ),
        if (description != null && description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Text(description, style: theme.textTheme.bodyLarge),
          ),
      ],
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.imageUri});

  static const double _maxHeight = 260;

  final Uri? imageUri;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.restaurant, size: 56)),
    );

    // 16:9 on a phone, but capped so wide screens don't push the details off-screen.
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: (constraints.maxWidth * 9 / 16).clamp(0, _maxHeight).toDouble(),
        child: imageUri == null
            ? placeholder
            : Image.network(
                imageUri.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => placeholder,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const Center(child: CircularProgressIndicator()),
              ),
      ),
    );
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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
