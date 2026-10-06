class AppConstants {
  AppConstants._();

  /// Backend address. Override per build with `--dart-define=API_BASE_URL=https://...`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5080',
  );

  /// Turns a path the API returns (e.g. `/uploads/restaurants/a.png`) into a full URL.
  static Uri resolveApiUrl(String path) => Uri.parse(apiBaseUrl).resolve(path);
}
