import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../data/venue_me.dart';
import '../../data/venue_repository.dart';

/// Where the signed-in person stands. Starts over when someone else signs in.
final venueMeProvider = FutureProvider.autoDispose<VenueMe>((ref) {
  ref.watch(authControllerProvider.select((session) => session?.refreshToken));

  return ref.watch(venueRepositoryProvider).getMe();
});
