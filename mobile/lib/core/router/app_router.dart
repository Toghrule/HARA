import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/customer_choice.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_owner_screen.dart';
import '../../features/auth/presentation/screens/register_staff_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/company_info/presentation/screens/about_screen.dart';
import '../../features/company_info/presentation/screens/contact_screen.dart';
import '../../features/faq/presentation/screens/faq_screen.dart';
import '../../features/reservations/data/reservation.dart';
import '../../features/reservations/presentation/screens/reservation_code_screen.dart';
import '../../features/restaurants/presentation/screens/restaurant_detail_screen.dart';
import '../../features/restaurants/presentation/screens/restaurants_screen.dart';
import '../../features/venue/presentation/screens/venue_home_screen.dart';
import '../auth/auth_controller.dart';

/// Screens only for people who are not signed in; a signed-in owner or waiter is sent to their own home.
const _guestOnlyPaths = {'/welcome', '/login', '/register-owner', '/register-staff'};

final appRouterProvider = Provider<GoRouter>((ref) {
  // Signing in or out, or choosing "Continue as a customer", must re-evaluate where the person belongs.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider.select((session) => session != null), (previous, next) => refresh.value++);
  ref.listen(customerChoiceProvider, (previous, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    // Someone who is still signed in from last time goes straight to their restaurant.
    initialLocation: ref.read(authControllerProvider) != null ? '/venue' : '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(authControllerProvider) != null;
      final path = state.uri.path;

      if (signedIn && _guestOnlyPaths.contains(path)) return '/venue';
      if (!signedIn && path.startsWith('/venue')) return '/welcome';

      // First launch: ask whether this is a customer or a restaurant owner/waiter, once.
      if (!signedIn && path == '/' && !ref.read(customerChoiceProvider)) return '/welcome';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RestaurantsScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register-owner',
        builder: (context, state) => const RegisterOwnerScreen(),
      ),
      GoRoute(
        path: '/register-staff',
        builder: (context, state) => const RegisterStaffScreen(),
      ),
      GoRoute(
        path: '/venue',
        builder: (context, state) => const VenueHomeScreen(),
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
