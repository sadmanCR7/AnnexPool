import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/data/providers/auth_provider.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(tokenStorageProvider));
});

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Re-fetch profile when auth state changes (e.g., login/logout)
  ref.watch(authStateProvider);
  final service = ref.watch(profileServiceProvider);
  return await service.getProfile();
});

final publicProfileProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final service = ref.watch(profileServiceProvider);
  return service.getPublicProfile(userId);
});
