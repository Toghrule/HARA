class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'http://localhost:5080';

  /// Turns a path the API returns (e.g. `/uploads/restaurants/a.png`) into a full URL.
  static Uri resolveApiUrl(String path) => Uri.parse(apiBaseUrl).resolve(path);
}
