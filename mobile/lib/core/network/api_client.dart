import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

class ApiClient {
  ApiClient() : dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

  final Dio dio;
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
