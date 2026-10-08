import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../l10n/locale_provider.dart';

class ApiClient {
  /// [languageCode] is sent with every request (`?lang=`) so the server answers in the app's language.
  ApiClient({this.languageCode = defaultLanguageCode})
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            queryParameters: {'lang': languageCode},
          ),
        );

  final String languageCode;
  final Dio dio;
}

/// Rebuilt when the language changes, which in turn reloads everything fetched through it.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(languageCode: ref.watch(localeProvider).languageCode);
});
