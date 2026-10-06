import 'package:url_launcher/url_launcher.dart';

import '../data/restaurant.dart';

/// Google Maps link for a restaurant: its exact coordinates when the admin has
/// set them, otherwise a search for its address.
Uri googleMapsUri(Restaurant restaurant) => Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': restaurant.hasCoordinates
          ? '${restaurant.latitude},${restaurant.longitude}'
          : restaurant.address,
    });

Future<void> openInGoogleMaps(Restaurant restaurant) =>
    launchUrl(googleMapsUri(restaurant), mode: LaunchMode.externalApplication);
