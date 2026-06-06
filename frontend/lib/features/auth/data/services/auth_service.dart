import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_errors.dart';
import '../../../../core/storage/token_storage.dart';

class AuthService {
  late final Dio _authDio;
  final TokenStorage _tokenStorage;

  AuthService(this._tokenStorage) {
    _authDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.authBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'AnnexPool/1.0',
        },
        validateStatus: (status) {
          // Accept any status code to see the actual error
          return status != null;
        },
      ),
    );

    print('✅ AuthService initialized with baseUrl: ${AppConfig.authBaseUrl}');

    // Add ultra-detailed debug logging
    if (kDebugMode) {
      _authDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('🔵 AUTH REQUEST STARTED');
            print('URL: ${options.uri}');
            print('Method: ${options.method}');
            print('Headers: ${options.headers}');
            print('Data: ${options.data}');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('🟢 AUTH RESPONSE RECEIVED');
            print('Status: ${response.statusCode}');
            print('Data: ${response.data}');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            return handler.next(response);
          },
          onError: (error, handler) {
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('🔴 AUTH ERROR OCCURRED');
            print('Error Type: ${error.type}');
            print('Error Message: ${error.message}');
            print('Error: $error');
            print('Request: ${error.requestOptions.uri}');
            print('Response Status: ${error.response?.statusCode}');
            print('Response Data: ${error.response?.data}');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            return handler.next(error);
          },
        ),
      );
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _authDio.post(
        '/login',
        data: {'email': email.toLowerCase().trim(), 'password': password},
      );
      return _normalizeUser(response.data);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e, 'Login failed'));
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await _authDio.post(
        '/register',
        data: {
          'name': name.trim(),
          'email': email.toLowerCase().trim(),
          'password': password,
          'role': role,
        },
      );
      return _normalizeUser(response.data);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e, 'Registration failed'));
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    final dio = ApiClient.create(_tokenStorage);
    try {
      final response = await dio.get('/users/profile');
      return _normalizeUser(response.data);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e, 'Session expired'));
    }
  }

  Map<String, dynamic> _normalizeUser(dynamic data) {
    if (data is! Map) return {};
    final map = Map<String, dynamic>.from(data);
    if (map['_id'] != null) {
      map['_id'] = map['_id'].toString();
    }
    if (map['token'] != null) {
      map['token'] = map['token'].toString();
    }
    return map;
  }
}
