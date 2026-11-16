import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/location/user_location_provider.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/hara_bottom_nav.dart';
import '../../../core/widgets/hara_logo.dart';
import '../../../core/widgets/hara_ui.dart';
import '../../../core/widgets/language_menu.dart';
import '../../../l10n/app_localizations.dart';
import '../../restaurants/data/restaurant.dart';
import '../../restaurants/data/restaurants_repository.dart';

/// Every restaurant that has a place on the map, for the map tab (no filters: the map shows them all).
final mapRestaurantsProvider = FutureProvider.autoDispose<List<Restaurant>>((ref) async {
  final restaurants = await ref.watch(restaurantsRepositoryProvider).getRestaurants(pageSize: 100);

  return restaurants.where((restaurant) => restaurant.hasCoordinates).toList();
});

/// Whether the map draws its picture tiles from the internet. Off only in tests, which have no network.
final mapTilesProvider = Provider<bool>((ref) => true);

/// Baku: where the map starts when nothing else says where to look.
const _baku = LatLng(40.4093, 49.8671);

/// The map tab: every place as a pin, a tap shows the place with a way into its page. The map is OpenStreetMap, which needs no key.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  Restaurant? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final restaurantsAsync = ref.watch(mapRestaurantsProvider);
    final position = ref.watch(userLocationProvider.select((location) => location.position));

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
      bottomNavigationBar: const HaraBottomNav(current: HomeTab.map),
      body: restaurantsAsync.when(
        data: (restaurants) => _MapBody(
          restaurants: restaurants,
          start: position == null ? null : LatLng(position.latitude, position.longitude),
          selected: _selected,
          onSelect: (restaurant) => setState(() => _selected = restaurant),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorView(
          message: l10n.couldntLoadRestaurants(apiErrorMessage(error, l10n)),
          onRetry: () => ref.invalidate(mapRestaurantsProvider),
        ),
      ),
    );
  }
}

class _MapBody extends ConsumerWidget {
  const _MapBody({required this.restaurants, required this.start, required this.selected, required this.onSelect});

  final List<Restaurant> restaurants;
  final LatLng? start;
  final Restaurant? selected;
  final ValueChanged<Restaurant?> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tiles = ref.watch(mapTilesProvider);
    final center = start ?? (restaurants.isEmpty ? _baku : LatLng(restaurants.first.latitude, restaurants.first.longitude));

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: start != null ? 14 : 12,
            minZoom: 4,
            maxZoom: 18,
            onTap: (tapPosition, point) => onSelect(null),
          ),
          children: [
            if (tiles)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hara.hara',
              ),
            MarkerLayer(
              markers: [
                if (start != null)
                  Marker(
                    point: start!,
                    width: 22,
                    height: 22,
                    child: Container(
                      key: const Key('myLocation'),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                for (final restaurant in restaurants)
                  Marker(
                    point: LatLng(restaurant.latitude, restaurant.longitude),
                    width: 64,
                    height: 64,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      key: Key('pin-${restaurant.id}'),
                      onTap: () => onSelect(restaurant),
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: selected?.id == restaurant.id ? 62 : 52,
                            color: selected?.id == restaurant.id ? AppTheme.gold : AppTheme.deepPurple,
                            shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
                          ),
                          if (restaurant.discountPercent > 0)
                            Positioned(
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: scheme.secondary, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 1.5)),
                                child: Text('-${restaurant.discountPercent}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: scheme.onSecondary)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // OpenStreetMap asks to be named wherever its map is shown.
            const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
          ],
        ),
        if (selected != null) Positioned(left: 12, right: 12, bottom: 12, child: _PlaceCard(restaurant: selected!)),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cuisines = restaurant.cuisines.take(2).map(l10n.cuisineName).join(', ');

    return Card(
      key: const Key('placeCard'),
      margin: EdgeInsets.zero,
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/restaurants/${restaurant.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.restaurant, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      [if (cuisines.isNotEmpty) cuisines, restaurant.address].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (restaurant.ratingAverage != null)
                      Text(l10n.ratingShort(restaurant.ratingAverage!.toStringAsFixed(1), restaurant.ratingCount), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (restaurant.discountPercent > 0) DiscountBadge(percent: restaurant.discountPercent),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
