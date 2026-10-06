import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/reservations/data/reservation.dart';
import '../../features/reservations/presentation/screens/reservation_code_screen.dart';
import '../../features/restaurants/presentation/screens/restaurants_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RestaurantsScreen(),
      ),
      GoRoute(
        path: '/reservation',
        // The reservation travels as route `extra`, which doesn't survive a
        // browser refresh; without it there's nothing to show, so go home.
        redirect: (context, state) => state.extra is Reservation ? null : '/',
        builder: (context, state) => ReservationCodeScreen(
          reservation: state.extra! as Reservation,
        ),
      ),
    ],
  );
});
