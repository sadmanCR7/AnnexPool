import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

// 1. Use NotifierProvider instead of StateNotifierProvider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({this.isLoading = false, this.error, this.isAuthenticated = false});
}

// 2. Extend Notifier instead of StateNotifier
class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  // 3. Override the build method (required by Notifier)
  @override
  AuthState build() {
    // Check auth status asynchronously right after initialization
    Future.microtask(() => checkAuthStatus());
    return AuthState(); // Return the initial default state
  }

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      state = AuthState(isAuthenticated: true);
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      final response = await ApiClient.instance.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      await _storage.write(key: 'jwt_token', value: response.data['token']);
      state = AuthState(isAuthenticated: true, isLoading: false);
      return true;
    } on DioException catch (e) {
      state = AuthState(error: e.response?.data['message'] ?? 'Login failed', isLoading: false);
      return false;
    }
  }
  Future<bool> register(String name, String email, String password, String role) async {
    state = AuthState(isLoading: true);
    try {
      final response = await ApiClient.instance.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      
      await _storage.write(key: 'jwt_token', value: response.data['token']);
      state = AuthState(isAuthenticated: true, isLoading: false);
      return true;
    } on DioException catch (e) {
      state = AuthState(error: e.response?.data['message'] ?? 'Registration failed', isLoading: false);
      return false;
    }
  }
}