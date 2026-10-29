import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../reservations/presentation/reserve_flow.dart';
import '../../data/restaurant.dart';
import '../availability_text.dart';
import '../distance_text.dart';
import '../providers/favorites_provider.dart';
import '../widgets/restaurant_gallery.dart';
import '../../data/restaurant_filters.dart';
import '../../../../core/location/user_location_provider.dart';
import '../widgets/opening_hours_list.dart';
import '../maps_launcher.dart';
import '../providers/restaurant_provider.dart';

class RestaurantDetailScreen extends ConsumerWidget {
  const RestaurantDetailScreen({required this.restaurantId, super.key});

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantProvider(restaurantId));
    final restaurant = restaurantAsync.valueOrNull;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant?.name ?? l10n.restaurantFallbackTitle),
        actions: [
          if (restaurant != null) _FavoriteButton(restaurantId: restaurant.id),
        ],
      ),
      body: restaurantAsync.when(
        data: (restaurant) => _Details(restaurant: restaurant),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          message: error is DioException && error.response?.statusCode == 404
              ? l10n.restaurantNoLongerAvailable
              : apiErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(restaurantProvider(restaurantId)),
        ),
      ),
      bottomNavigationBar: restaurant == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: restaurant.availability.acceptingRequests ? () => startReservation(context, restaurant) : null,
                  icon: const Icon(Icons.event_seat),
                  label: Text(l10n.reserveTable),
                ),
              ),
            ),
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final position = ref.watch(userLocationProvider.select((location) => location.position));
    final distance = position != null && restaurant.hasCoordinates
        ? distanceText(l10n, distanceKm(position, restaurant.latitude, restaurant.longitude))
        : null;
    final description = restaurant.description?.trim();
    final phone = restaurant.phoneNumber?.trim();

    return ListView(
      children: [
        RestaurantGallery(photos: restaurant.photoUris),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(restaurant.name, style: theme.textTheme.headlineSmall),
              if (restaurant.cuisines.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  key: const Key('cuisines'),
                  spacing: 8,
                  children: [for (final code in restaurant.cuisines) Chip(label: Text(l10n.cuisineName(code)))],
                ),
              ],
              if (restaurant.discountPercent > 0) ...[
                const SizedBox(height: 12),
                Chip(
                  avatar: const Icon(Icons.local_offer_outlined, size: 18),
                  label: Text(AppLocalizations.of(context).discountWithCode(restaurant.discountPercent)),
                ),
              ],
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(restaurant.address),
          subtitle: distance == null ? null : Text(distance, key: const Key('distance')),
          trailing: const Icon(Icons.map_outlined),
          onTap: () => openInGoogleMaps(restaurant),
        ),
        if (restaurant.openingHours.isNotEmpty)
          ExpansionTile(
            key: const Key('hoursTile'),
            leading: const Icon(Icons.schedule),
            title: Text(
              availabilityText(AppLocalizations.of(context), restaurant.availability).ifEmpty(AppLocalizations.of(context).openingHoursTitle),
              key: const Key('availability'),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
            children: [OpeningHoursList(hours: restaurant.openingHours)],
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

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isFavorite = ref.watch(favoritesProvider.select((favorites) => favorites.contains(restaurantId)));

    return IconButton(
      key: const Key('favoriteButton'),
      tooltip: isFavorite ? l10n.removeFavorite : l10n.addFavorite,
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Theme.of(context).colorScheme.error : null),
      onPressed: () => ref.read(favoritesProvider.notifier).toggle(restaurantId),
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
            FilledButton(onPressed: onRetry, child: Text(AppLocalizations.of(context).retry)),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
