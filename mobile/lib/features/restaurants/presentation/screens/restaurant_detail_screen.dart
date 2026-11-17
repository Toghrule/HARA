import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/feature_flags.dart';
import '../../../../core/widgets/hara_ui.dart';
import '../../../discounts/data/discounts_repository.dart';
import '../../../discounts/presentation/discount_flow.dart';
import '../../../reservations/presentation/reserve_flow.dart';
import '../../data/restaurant.dart';
import '../availability_text.dart';
import '../providers/favorites_provider.dart';
import '../widgets/restaurant_gallery.dart';
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
        data: (restaurant) => _ViewRecorder(restaurantId: restaurant.id, child: _Details(restaurant: restaurant)),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          message: error is DioException && error.response?.statusCode == 404
              ? l10n.restaurantNoLongerAvailable
              : apiErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(restaurantProvider(restaurantId)),
        ),
      ),
      bottomNavigationBar: restaurant != null && !FeatureFlags.reservationsEnabled && restaurant.discountPercent > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  key: const Key('getDiscount'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: () => getDiscount(context, ref, restaurant),
                  icon: const Icon(Icons.local_offer_outlined),
                  label: Text(l10n.getDiscount),
                ),
              ),
            )
          : restaurant == null || !FeatureFlags.reservationsEnabled
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: restaurant.availability.acceptingRequests ? () => startReservation(context, restaurant) : null,
                  icon: const Icon(Icons.event_seat),
                  label: Text(l10n.reserveTable),
                ),
              ),
            ),
    );
  }
}

/// Tells HARA once, when the restaurant's page opens, that a customer looked at it (counted for the admin, anonymously).
class _ViewRecorder extends ConsumerStatefulWidget {
  const _ViewRecorder({required this.restaurantId, required this.child});

  final String restaurantId;
  final Widget child;

  @override
  ConsumerState<_ViewRecorder> createState() => _ViewRecorderState();
}

class _ViewRecorderState extends ConsumerState<_ViewRecorder> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(discountsRepositoryProvider).recordEvent(widget.restaurantId, RestaurantEvent.view));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Details extends ConsumerWidget {
  const _Details({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
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
              Text(restaurant.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              if (restaurant.cuisines.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  key: const Key('cuisines'),
                  spacing: 8,
                  children: [for (final code in restaurant.cuisines) Chip(label: Text(l10n.cuisineName(code)))],
                ),
              ],
              if (restaurant.ratingAverage != null) ...[
                const SizedBox(height: 8),
                Row(
                  key: const Key('rating'),
                  children: [
                    Text(l10n.ratingShort(restaurant.ratingAverage!.toStringAsFixed(1), restaurant.ratingCount), style: theme.textTheme.bodyLarge),
                  ],
                ),
              ],
              if (restaurant.discountPercent > 0) ...[
                const SizedBox(height: 14),
                Container(
                  key: const Key('discountBanner'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      DiscountBadge(percent: restaurant.discountPercent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          FeatureFlags.reservationsEnabled ? l10n.discountWithCode(restaurant.discountPercent) : l10n.discountOffer(restaurant.discountPercent),
                          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        _SectionTitle(l10n.sectionAddress),
        _SectionCard(
          child: ListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(restaurant.address),
          trailing: const Icon(Icons.map_outlined),
          onTap: () {
            unawaited(ref.read(discountsRepositoryProvider).recordEvent(restaurant.id, RestaurantEvent.directions));
            unawaited(openInGoogleMaps(restaurant));
          },
        ),
        ),
        if (restaurant.openingHours.isNotEmpty) ...[
          _SectionTitle(l10n.openingHoursTitle),
          _SectionCard(
            child: ExpansionTile(
            key: const Key('hoursTile'),
            leading: const Icon(Icons.schedule),
            title: Text(
              availabilityText(AppLocalizations.of(context), restaurant.availability).ifEmpty(AppLocalizations.of(context).openingHoursTitle),
              key: const Key('availability'),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
            children: [OpeningHoursList(hours: restaurant.openingHours)],
          ),
          ),
        ],
        if (phone != null && phone.isNotEmpty) ...[
          _SectionTitle(l10n.sectionContact),
          _SectionCard(
            child: ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(phone),
              onTap: () => launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', ''))),
            ),
          ),
        ],
        if (description != null && description.isNotEmpty) ...[
          _SectionTitle(l10n.sectionAbout),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Text(description, style: theme.textTheme.bodyLarge),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

/// A small heading above a part of the restaurant's page.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      );
}

/// A rounded card around a row of the restaurant's page.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
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
