import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/token_source.dart';
import '../constants/app_constants.dart';
import '../customer/customer_controller.dart';
import '../l10n/locale_provider.dart';

class ApiClient {
  /// [languageCode] is sent with every request (`?lang=`) so the server answers in the app's language.
  /// With [tokens], requests to the restaurant-side API carry the signed-in person's token and are
  /// retried once with a renewed one if the server says it expired.
  ApiClient({this.languageCode = defaultLanguageCode, TokenSource? tokens, TokenSource? customerTokens})
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            queryParameters: {'lang': languageCode},
          ),
        ) {
    if (tokens != null) dio.interceptors.add(_AuthInterceptor(tokens, dio, _needsSignIn));
    if (customerTokens != null) dio.interceptors.add(_AuthInterceptor(customerTokens, dio, _needsCustomerSignIn));
  }

  final String languageCode;
  final Dio dio;
}

/// Only the restaurant-side API (and deleting one's own account) needs, and should ever receive, the sign-in token.
bool _needsSignIn(RequestOptions options) =>
    options.path.startsWith('/api/venue') || options.path == '/api/auth/delete-account';

/// Only the customer's own endpoints (their profile and reviews) get the customer's token.
bool _needsCustomerSignIn(RequestOptions options) => options.path.startsWith('/api/customer');

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokens, this._dio, this._applies);

  static const _retriedKey = 'retriedAfterRefresh';

  final TokenSource _tokens;
  final Dio _dio;
  final bool Function(RequestOptions) _applies;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_applies(options)) {
      final token = await _tokens.validAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException error, ErrorInterceptorHandler handler) async {
    final request = error.requestOptions;
    final refused = error.response?.statusCode == 401 && _applies(request);

    if (!refused || request.extra[_retriedKey] == true) {
      handler.next(error);
      return;
    }

    // The token was refused (revoked or expired early): renew once and repeat the request.
    final token = await _tokens.refreshAccessToken();
    if (token == null) {
      handler.next(error);
      return;
    }

    try {
      final retry = request.copyWith(
        headers: {...request.headers, 'Authorization': 'Bearer $token'},
        extra: {...request.extra, _retriedKey: true},
      );
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}

/// Rebuilt when the language changes, which in turn reloads everything fetched through it.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    languageCode: ref.watch(localeProvider).languageCode,
    tokens: ref.read(authControllerProvider.notifier),
    customerTokens: ref.read(customerControllerProvider.notifier),
  );
});
