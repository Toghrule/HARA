import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

class ApiClient {
  ApiClient() : dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

  final Dio dio;
}
