import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../services/app_socket_service.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(tokenStorageProvider));
});

final appSocketServiceProvider = Provider<AppSocketService>((ref) {
  final service = AppSocketService();
  ref.onDispose(() => service.disconnect());
  return service;
});

class UnreadCountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int count) => state = count;
  void increment() => state += 1;
  void clear() => state = 0;
}

final unreadCountProvider = NotifierProvider<UnreadCountNotifier, int>(UnreadCountNotifier.new);

final notificationsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(notificationServiceProvider).getNotifications();
});

final notificationBootstrapProvider = FutureProvider<void>((ref) async {
  ref.watch(authStateProvider);
  final token = await ref.read(tokenStorageProvider).read();
  if (token == null) return;

  final count = await ref.read(notificationServiceProvider).getUnreadCount();
  ref.read(unreadCountProvider.notifier).set(count);

  ref.read(appSocketServiceProvider).connect(
        token,
        onNotification: (_) {
          ref.read(unreadCountProvider.notifier).increment();
          ref.invalidate(notificationsProvider);
        },
      );
});
