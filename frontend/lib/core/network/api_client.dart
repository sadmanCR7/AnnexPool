import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io'; // For Platform

class ApiClient {
  // Automatically choose the correct localhost based on the platform
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1'; // Web Browser
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api/v1'; // Android Emulator
    } else {
      return 'http://localhost:5000/api/v1'; // Windows, Mac, iOS Simulator
    }
  }

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static Dio get instance {
    // Prevent adding multiple interceptors during hot reload
    if (_dio.interceptors.isEmpty) {
      _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
    }
    return _dio;
  }
}