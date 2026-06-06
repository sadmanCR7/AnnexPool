import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static String get baseUrl => AppConfig.apiBaseUrl;

  static Dio create(TokenStorage tokenStorage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Configure HTTP client for HTTPS
    dio.httpClientAdapter = HttpClientAdapter()
      ..onHttpClientCreate = (HttpClient client) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) =>
                false; // Validate certificates
        return client;
      };

    // Add authorization interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            print('🔵 API Request: ${options.method} ${options.uri}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print(
              '🟢 API Response: ${response.statusCode} ${response.requestOptions.uri}',
            );
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('🔴 API Error: ${error.type} ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}
