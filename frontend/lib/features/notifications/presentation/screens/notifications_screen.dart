import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String? type) {
    switch (type) {
      case 'ride':
        return Icons.directions_car;
      case 'chat':
        return Icons.chat;
      case 'emergency':
        return Icons.sos;
      case 'rating':
        return Icons.star;
      case 'system':
        return Icons.info_outline;
      case 'promo':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String? type) {
    if (type == 'emergency') return AppTheme.errorColor;
    if (type == 'promo') return Colors.amber;
    return AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationServiceProvider).markAllAsRead();
              ref.read(unreadCountProvider.notifier).clear();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              final count = await ref.read(notificationServiceProvider).getUnreadCount();
              ref.read(unreadCountProvider.notifier).set(count);
            },
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = items[index];
                final isRead = n['isRead'] == true;
                final type = n['type'] as String?;
                final data = n['data'] is Map ? (n['data'] as Map) : null;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _colorForType(type).withValues(alpha: 0.1),
                    child: Icon(_iconForType(type), color: _colorForType(type), size: 20),
                  ),
                  title: Text(
                    n['title'] ?? '',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(n['body'] ?? ''),
                  trailing: isRead ? null : const Icon(Icons.circle, size: 10, color: AppTheme.primaryColor),
                  onTap: () async {
                    if (!isRead) {
                      await ref.read(notificationServiceProvider).markAsRead(n['_id']);
                      ref.invalidate(notificationsProvider);
                      final count = await ref.read(notificationServiceProvider).getUnreadCount();
                      ref.read(unreadCountProvider.notifier).set(count);
                    }

                    if (!context.mounted) return;

                    final title = n['title']?.toString() ?? '';

                    if (type == 'chat') {
                      // Direct message notification → open specific chat
                      if (data?['chatId'] != null) {
                        context.push('/chats/${data!['chatId']}');
                      }
                    } else if (type == 'ride') {
                      // "Ride Completed" → open chat for review
                      if (title == 'Ride Completed' && data?['chatId'] != null) {
                        context.push('/chats/${data!['chatId']}');
                      } else if (title == 'New Ride Join Request') {
                        context.push('/driver-dashboard');
                      } else {
                        // All other ride notifications → my requests/rides page
                        context.push('/my-requests');
                      }
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
