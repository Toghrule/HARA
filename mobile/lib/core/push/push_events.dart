import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/reservations/presentation/providers/active_reservations_provider.dart';
import '../../features/venue/presentation/providers/venue_providers.dart';
import '../router/app_router.dart';
import 'push_service.dart';

/// Reacts to notifications: a new one brings the screens up to date right away (instead of at the next refresh),
/// and tapping one opens where it belongs: the restaurant's home for a new request, the customer's home (with
/// their reservation) for an answer.
final pushEventsProvider = Provider<void>((ref) {
  final service = ref.watch(pushServiceProvider);

  void refresh(PushEvent event) {
    if (event.isNewRequest) {
      ref.invalidate(venueReservationsProvider(ReservationFilter.pending));
    } else {
      unawaited(ref.read(activeReservationsProvider.notifier).refresh());
    }
  }

  final subscriptions = [
    service.arrivals.listen(refresh),
    service.taps.listen((event) {
      refresh(event);
      ref.read(appRouterProvider).go(event.isNewRequest ? '/venue' : '/');
    }),
  ];

  ref.onDispose(() {
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
  });
});
