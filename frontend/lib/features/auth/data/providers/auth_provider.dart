import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/storage/token_storage.dart';
import '../services/auth_service.dart';
import '../../../rides/data/providers/ride_offer_provider.dart';
import '../../../rides/data/providers/ride_request_provider.dart';
import '../../../notifications/data/providers/notification_provider.dart';
import '../../../chat/data/providers/chat_provider.dart';
import '../../../chat/data/services/chat_socket_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(tokenStorageProvider));
});

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({this.isLoading = false, this.error, this.user});

  AuthState copyWith({bool? isLoading, String? error, Map<String, dynamic>? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState();

  Future<bool> restoreSession() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.read();
    if (token == null) return false;

    try {
      final profile = await ref.read(authServiceProvider).getMe();
      state = state.copyWith(user: profile);
      return true;
    } catch (_) {
      await tokenStorage.delete();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ref.read(authServiceProvider).login(email, password);
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Server did not return a login token');
      }
      await ref.read(tokenStorageProvider).write(token);
      // Fetch full profile so gender/isVerifiedFemale etc. are available
      final profile = await ref.read(authServiceProvider).getMe();
      state = state.copyWith(isLoading: false, user: profile);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ref.read(authServiceProvider).register(name, email, password, role);
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Server did not return a login token');
      }
      await ref.read(tokenStorageProvider).write(token);
      // Fetch full profile so gender/isVerifiedFemale etc. are available
      final profile = await ref.read(authServiceProvider).getMe();
      state = state.copyWith(isLoading: false, user: profile);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).delete();
    _invalidateCaches();
    state = AuthState();
  }

  void _invalidateCaches() {
    ref.invalidate(myRideOffersProvider);
    ref.invalidate(myJoinedOffersProvider);
    ref.invalidate(myRideRequestsProvider);
    ref.invalidate(myRespondedRequestsProvider);
    ref.invalidate(myChatsProvider);
    ref.invalidate(notificationsProvider);
    ref.read(chatSocketServiceProvider).disconnect(); // Cleanly disconnect old socket
    ref.invalidate(chatSocketServiceProvider); // Reset the provider
  }
}
