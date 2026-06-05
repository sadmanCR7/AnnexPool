import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../services/safety_service.dart';

final safetyServiceProvider = Provider<SafetyService>((ref) {
  return SafetyService(ref.watch(tokenStorageProvider));
});

final safetyPreferencesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(safetyServiceProvider).getPreferences();
});
