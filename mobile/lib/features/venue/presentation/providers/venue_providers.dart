import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../reservations/data/reservation_state.dart';
import '../../data/venue_me.dart';
import '../../data/venue_models.dart';
import '../../data/venue_repository.dart';

/// Everything on the restaurant side belongs to whoever is signed in, so it all starts over when
/// someone else signs in.
void _dependOnSignedInPerson(Ref ref) =>
    ref.watch(authControllerProvider.select((session) => session?.refreshToken));

/// Where the signed-in person stands.
final venueMeProvider = FutureProvider.autoDispose<VenueMe>((ref) {
  _dependOnSignedInPerson(ref);

  return ref.watch(venueRepositoryProvider).getMe();
});

/// Which reservations the list shows.
enum ReservationFilter {
  active(ReservationState.active),
  used(ReservationState.redeemed),
  all(null);

  const ReservationFilter(this.status);

  final ReservationState? status;
}

final venueReservationsProvider = FutureProvider.autoDispose.family<List<VenueReservation>, ReservationFilter>((ref, filter) {
  _dependOnSignedInPerson(ref);

  return ref.watch(venueRepositoryProvider).getReservations(status: filter.status);
});

/// The owner's team, waiting requests first.
final venueStaffProvider = FutureProvider.autoDispose<List<StaffMember>>((ref) {
  _dependOnSignedInPerson(ref);

  return ref.watch(venueRepositoryProvider).getStaff();
});

final venueChangeRequestsProvider = FutureProvider.autoDispose<List<ChangeRequest>>((ref) {
  _dependOnSignedInPerson(ref);

  return ref.watch(venueRepositoryProvider).getChangeRequests();
});
