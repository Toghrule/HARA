import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';

/// Turns an error from the API into one short message a customer can read.
///
/// The backend reports validation problems as `{"errors": {"Field": ["message"]}}`
/// and other failures as `{"title": "..."}`. Those server messages are English; the
/// connection and generic messages are shown in the app's language.
String apiErrorMessage(Object error, AppLocalizations l10n) {
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
    if (error.response == null) return l10n.errorCantReachServer;
  }
  return l10n.errorSomethingWrong;
}
