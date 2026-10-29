import '../../../l10n/app_localizations.dart';

/// "350 m" below a kilometre (to the nearest 10 m), "1.2 km" above.
String distanceText(AppLocalizations l10n, double km) {
  if (km < 1) {
    final meters = (km * 1000 / 10).round() * 10;

    return l10n.distanceMeters('${meters < 10 ? 10 : meters}');
  }

  return l10n.distanceKm(km.toStringAsFixed(1));
}
