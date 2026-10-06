import 'package:dio/dio.dart';

/// Turns an error from the API into one short message a customer can read.
///
/// The backend reports validation problems as `{"errors": {"Field": ["message"]}}`
/// and other failures as `{"title": "..."}`.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return '${first.first}';
      }
      final title = data['title'];
      if (title is String && title.isNotEmpty && error.response?.statusCode != 500) {
        return title;
      }
    }
    if (error.response == null) {
      return 'Can\'t reach the server. Check your connection and try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}
