import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hara/core/network/api_error.dart';

DioException _error({int? status, Object? data}) {
  final options = RequestOptions(path: '/x');

  return DioException(
    requestOptions: options,
    response: status == null ? null : Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('uses the first validation message the server returns', () {
    final error = _error(status: 400, data: {
      'title': 'Validation failed',
      'errors': {
        'PhoneNumber': ['This phone number already has an active reservation.'],
      },
    });

    expect(apiErrorMessage(error), 'This phone number already has an active reservation.');
  });

  test('shows the rate-limit message for HTTP 429', () {
    final error = _error(status: 429, data: {'title': 'Too many attempts. Please try again later.', 'status': 429});

    expect(apiErrorMessage(error), 'Too many attempts. Please try again later.');
  });

  test('explains a connection problem when there is no response', () {
    expect(apiErrorMessage(_error()), contains('Can\'t reach the server'));
  });

  test('hides server-error details behind a generic message', () {
    final error = _error(status: 500, data: {'title': 'An unexpected error occurred.', 'status': 500});

    expect(apiErrorMessage(error), 'Something went wrong. Please try again.');
    expect(apiErrorMessage(StateError('boom')), 'Something went wrong. Please try again.');
  });
}
