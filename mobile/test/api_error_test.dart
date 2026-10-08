import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/l10n/app_localizations_en.dart';
import 'package:hara/core/network/api_error.dart';

DioException _error({int? status, Object? data}) {
  final options = RequestOptions(path: '/x');

  return DioException(
    requestOptions: options,
    response: status == null ? null : Response(requestOptions: options, statusCode: status, data: data),
  );
}

final l10n = AppLocalizationsEn();

void main() {
  test('uses the first validation message the server returns', () {
    final error = _error(status: 400, data: {
      'title': 'Validation failed',
      'errors': {
        'PhoneNumber': ['This phone number already has an active reservation.'],
      },
    });

    expect(apiErrorMessage(error, l10n), 'This phone number already has an active reservation.');
  });

  test('shows the rate-limit message for HTTP 429', () {
    final error = _error(status: 429, data: {'title': 'Too many attempts. Please try again later.', 'status': 429});

    expect(apiErrorMessage(error, l10n), 'Too many attempts. Please try again later.');
  });

  test('explains a connection problem when there is no response', () {
    expect(apiErrorMessage(_error(), l10n), contains('Can\'t reach the server'));
  });

  test('hides server-error details behind a generic message', () {
    final error = _error(status: 500, data: {'title': 'An unexpected error occurred.', 'status': 500});

    expect(apiErrorMessage(error, l10n), 'Something went wrong. Please try again.');
    expect(apiErrorMessage(StateError('boom'), l10n), 'Something went wrong. Please try again.');
  });
}
