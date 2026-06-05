import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../services/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(ref.watch(tokenStorageProvider));
});

final adminAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(adminServiceProvider).getAnalytics();
});

class AdminUserSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final adminUserSearchProvider = NotifierProvider<AdminUserSearchNotifier, String>(
  AdminUserSearchNotifier.new,
);

final adminUsersProvider = FutureProvider<List<dynamic>>((ref) async {
  final search = ref.watch(adminUserSearchProvider);
  return ref.watch(adminServiceProvider).getUsers(
        search: search.isEmpty ? null : search,
      );
});

final adminReportsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(adminServiceProvider).getReports();
});

final adminOffersProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(adminServiceProvider).getOffers();
});

final adminRequestsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(adminServiceProvider).getRequests();
});

final adminSosProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(adminServiceProvider).getActiveSos();
});
