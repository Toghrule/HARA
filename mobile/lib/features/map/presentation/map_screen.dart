import 'dart:ui' as ui;

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

class _MapBody extends ConsumerStatefulWidget {
  const _MapBody({required this.restaurants, required this.start, required this.selected, required this.onSelect});

  final List<Restaurant> restaurants;
  final LatLng? start;
  final Restaurant? selected;
  final ValueChanged<Restaurant?> onSelect;

  @override
  ConsumerState<_MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends ConsumerState<_MapBody> {
  final _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// A group of places that sit too close to tell apart: zoom in on them. Places on exactly the same spot cannot be pulled apart by
  /// zooming, so the first of them is shown instead.
  void _openGroup(List<Restaurant> group) {
    final points = [for (final restaurant in group) LatLng(restaurant.latitude, restaurant.longitude)];
    final same = points.every((point) => point == points.first);

    if (same) {
      widget.onSelect(group.first);
      return;
    }

    _controller.fitCamera(CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(90), maxZoom: 17));
  }

  @override
  Widget build(BuildContext context) {
    final tiles = ref.watch(mapTilesProvider);
    final restaurants = widget.restaurants;
    final start = widget.start;
    final center = start ?? (restaurants.isEmpty ? _baku : LatLng(restaurants.first.latitude, restaurants.first.longitude));

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: center,
            initialZoom: start != null ? 14 : 12,
            minZoom: 4,
            maxZoom: 18,
            onTap: (tapPosition, point) => widget.onSelect(null),
          ),
          children: [
            if (tiles)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hara.hara',
              ),
            if (start != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: start,
                    width: 22,
                    height: 22,
                    child: Container(
                      key: const Key('myLocation'),
                      decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                    ),
                  ),
                ],
              ),
            _PlaceMarkers(restaurants: restaurants, selected: widget.selected, onSelect: widget.onSelect, onOpenGroup: _openGroup),
            // OpenStreetMap asks to be named wherever its map is shown.
            const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
          ],
        ),
        if (widget.selected != null) Positioned(left: 12, right: 12, bottom: 12, child: _PlaceCard(restaurant: widget.selected!)),
      ],
    );
  }
}

/// How close two places can be on the screen, in pixels, before they are shown as one group.
const _groupRadius = 70.0;

/// Every place as a photo card on the map, like a picture on a map: the restaurant's photo in a rounded rectangle with a small point to
/// where it is. Places too close to tell apart on the screen at this zoom become one card with "+N more" under it; a tap zooms in on them.
class _PlaceMarkers extends StatelessWidget {
  const _PlaceMarkers({required this.restaurants, required this.selected, required this.onSelect, required this.onOpenGroup});

  final List<Restaurant> restaurants;
  final Restaurant? selected;
  final ValueChanged<Restaurant?> onSelect;
  final ValueChanged<List<Restaurant>> onOpenGroup;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    // The places, in the pixels of the map at this zoom, gathered into groups: a place joins the first group that is close enough.
    final groups = <({Offset at, List<Restaurant> members})>[];
    for (final restaurant in restaurants) {
      final at = camera.projectAtZoom(LatLng(restaurant.latitude, restaurant.longitude));
      final index = groups.indexWhere((group) => (group.at - at).distance < _groupRadius);

      if (index < 0) {
        groups.add((at: at, members: [restaurant]));
      } else {
        groups[index].members.add(restaurant);
      }
    }

    return MarkerLayer(
      markers: [
        for (final group in groups)
          Marker(
            point: LatLng(group.members.first.latitude, group.members.first.longitude),
            width: 84,
            height: group.members.length > 1 ? 124 : 100,
            alignment: Alignment.topCenter,
            child: group.members.length == 1
                ? _PhotoPin(
                    key: Key('pin-${group.members.first.id}'),
                    restaurant: group.members.first,
                    selected: selected?.id == group.members.first.id,
                    onTap: () => onSelect(group.members.first),
                  )
                : _PhotoPin(
                    key: Key('group-${group.members.first.id}'),
                    restaurant: group.members.first,
                    selected: group.members.any((member) => member.id == selected?.id),
                    more: group.members.length - 1,
                    onTap: () => onOpenGroup(group.members),
                  ),
          ),
      ],
    );
  }
}

/// One card of the map: the photo, a gold edge when it is the chosen one, the discount in a corner, a point down to the place, and
/// "+N more" under it when it stands for a group.
class _PhotoPin extends StatelessWidget {
  const _PhotoPin({required this.restaurant, required this.selected, required this.onTap, this.more = 0, super.key});

  final Restaurant restaurant;
  final bool selected;
  final VoidCallback onTap;

  /// How many other places are hidden behind this one.
  final int more;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cover = restaurant.photoUris.isEmpty ? null : restaurant.photoUris.first;
    final placeholder = ColoredBox(
      color: scheme.primaryContainer,
      child: Center(
        child: Text(
          restaurant.name.trim().isEmpty ? '?' : restaurant.name.trim().characters.first.toUpperCase(),
          style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 26, fontWeight: FontWeight.w800),
        ),
      ),
    );
    final edge = selected ? AppTheme.gold : Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: selected ? 72 : 66,
            height: selected ? 72 : 66,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: edge, width: selected ? 4 : 3),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (cover == null)
                    placeholder
                  else
                    Image.network(cover.toString(), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => placeholder),
                  if (restaurant.discountPercent > 0 && more == 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: scheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text('-${restaurant.discountPercent}%', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: scheme.onSecondary)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // The little point of the card, down to where the place is.
          CustomPaint(size: const Size(16, 9), painter: _PointPainter(edge)),
          if (more > 0)
            Container(
              key: Key('more-${restaurant.id}'),
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
              child: Text(l10n.mapMore(more), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _PointPainter extends CustomPainter {
  _PointPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PointPainter old) => old.color != color;
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
