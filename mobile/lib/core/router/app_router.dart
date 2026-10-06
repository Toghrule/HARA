import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/company_info/presentation/screens/about_screen.dart';
import '../../features/company_info/presentation/screens/contact_screen.dart';
import '../../features/faq/presentation/screens/faq_screen.dart';
import '../../features/reservations/data/reservation.dart';
import '../../features/reservations/presentation/screens/reservation_code_screen.dart';
import '../../features/restaurants/presentation/screens/restaurant_detail_screen.dart';
import '../../features/restaurants/presentation/screens/restaurants_screen.dart';
import '../../features/submissions/presentation/screens/submit_restaurant_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RestaurantsScreen(),
      ),
      GoRoute(
        path: '/restaurants/:id',
        builder: (context, state) => RestaurantDetailScreen(
          restaurantId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/faq',
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/submit-restaurant',
        builder: (context, state) => const SubmitRestaurantScreen(),
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
