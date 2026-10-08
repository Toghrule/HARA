import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/venue_me.dart';
import '../../data/venue_models.dart';
import '../providers/venue_providers.dart';
import 'reservation_detail_card.dart';

/// The owner's view of their restaurant, the way to ask HARA for changes, and what became of earlier requests.
class RestaurantTab extends ConsumerWidget {
  const RestaurantTab({required this.restaurant, super.key});

  final VenueRestaurant restaurant;

  String _statusText(AppLocalizations l10n, ChangeRequestState status) => switch (status) {
        ChangeRequestState.pending => l10n.changeRequestPending,
        ChangeRequestState.approved => l10n.changeRequestApproved,
        ChangeRequestState.rejected => l10n.changeRequestRejected,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final requestsAsync = ref.watch(venueChangeRequestsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(venueChangeRequestsProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(restaurant.name, style: theme.textTheme.titleMedium),
              subtitle: Text('${restaurant.address}\n${l10n.discountLine(restaurant.discountPercent)}'),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('requestChange'),
            onPressed: () async {
              final sent = await context.push<bool>('/venue/change-request', extra: restaurant);
              if (sent == true) ref.invalidate(venueChangeRequestsProvider);
            },
            child: Text(l10n.requestAChange),
          ),
          const SizedBox(height: 24),
          Text(l10n.changeRequestsTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) return Padding(padding: const EdgeInsets.all(16), child: Text(l10n.noChangeRequests));

              return Column(
                children: [
                  for (final request in requests)
                    Card(
                      key: Key('request-${request.id}'),
                      child: ListTile(
                        title: Text(request.summary.join('\n'), maxLines: 4, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          [
                            '${_statusText(l10n, request.status)} · ${formatDayAndClock(request.createdAt)}',
                            if (request.adminNote != null && request.adminNote!.trim().isNotEmpty) l10n.adminReply(request.adminNote!.trim()),
                          ].join('\n'),
                        ),
                        isThreeLine: true,
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(apiErrorMessage(error, l10n), style: TextStyle(color: theme.colorScheme.error)),
            ),
          ),
        ],
      ),
    );
  }
}
