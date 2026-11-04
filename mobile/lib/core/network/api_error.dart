import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';

/// Turns an error from the API into one short message a customer can read.
///
/// The backend reports validation problems as `{"errors": {"Field": ["message"]}}`
/// and other failures as `{"title": "..."}`. Those server messages are English; the
/// connection and generic messages are shown in the app's language.
String apiErrorMessage(Object error, AppLocalizations l10n) {
  if (error is DioException && error.response?.statusCode == 429) return l10n.tooManyAttempts;

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

/// What went wrong when the confirmation code was typed or asked for again, in the app's language (the server's reasons are
/// English); anything unknown falls back to [apiErrorMessage].
String emailCodeErrorMessage(Object error, AppLocalizations l10n) {
  if (error is DioException && error.response?.statusCode == 400) {
    final data = error.response?.data;
    final errors = data is Map<String, dynamic> ? data['errors'] : null;
    final messages = errors is Map ? errors.values.expand((value) => value is List ? value : const []).map((value) => '$value'.toLowerCase()) : const <String>[];

    for (final message in messages) {
      if (message.contains('not right')) return l10n.emailCodeWrong;
      if (message.contains('expired')) return l10n.emailCodeExpired;
      if (message.contains('too many wrong')) return l10n.emailCodeTooManyTries;
      if (message.contains('wait a moment')) return l10n.emailCodeWait;
      if (message.contains('too many codes')) return l10n.emailCodeTooManyAsks;
      if (message.contains('six digits')) return l10n.emailCodeSixDigits;
      if (message.contains("couldn't send")) return l10n.emailCouldNotSend;
    }
  }

  return apiErrorMessage(error, l10n);
}

/// Like [apiErrorMessage], but turns the server's English sign-up complaints (email taken, weak password)
/// into messages in the app's language.
String registrationErrorMessage(Object error, AppLocalizations l10n) {
  if (error is DioException && error.response?.statusCode == 400) {
    final errors = (error.response?.data is Map<String, dynamic>) ? (error.response!.data as Map<String, dynamic>)['errors'] : null;

    if (errors is Map) {
      for (final entry in errors.entries) {
        final key = '${entry.key}'.toLowerCase();
        final messages = entry.value is List ? (entry.value as List).map((message) => '$message').toList() : <String>[];

        if (key == 'password') return l10n.passwordRules;
        if (key == 'email') {
          if (messages.any((message) => message.toLowerCase().contains("couldn't send"))) return l10n.emailCouldNotSend;
          return messages.any((message) => message.toLowerCase().contains('taken')) ? l10n.emailTaken : l10n.invalidEmail;
        }
      }
    }
  }

  return apiErrorMessage(error, l10n);
}
