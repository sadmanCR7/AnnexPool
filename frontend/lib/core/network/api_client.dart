import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static String get baseUrl => AppConfig.apiBaseUrl;

  static Dio create(TokenStorage tokenStorage) {
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
    return dio;
  }
}
