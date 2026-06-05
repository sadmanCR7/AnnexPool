import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../data/providers/chat_provider.dart';

class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(myChatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: chatsAsync.when(
        data: (chats) {
          final filteredChats = chats
              .where(
                (c) =>
                    c['lastMessage'] != null &&
                    c['lastMessage'].toString().isNotEmpty,
              )
              .toList();

          if (filteredChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Each ride route has its own chat thread',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final byRoute = <String, List<dynamic>>{};
          for (final chat in filteredChats) {
            final route = chat['routeLabel']?.toString() ?? 'Ride chat';
            byRoute.putIfAbsent(route, () => []).add(chat);
          }

          final routeKeys = byRoute.keys.toList()
            ..sort((a, b) {
              final aTime =
                  byRoute[a]!.first['lastMessageAt']?.toString() ?? '';
              final bTime =
                  byRoute[b]!.first['lastMessageAt']?.toString() ?? '';
              return bTime.compareTo(aTime);
            });

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myChatsProvider),
            child: ListView.builder(
              itemCount: routeKeys.fold<int>(
                0,
                (sum, key) => sum + 1 + byRoute[key]!.length,
              ),
              itemBuilder: (context, index) {
                var cursor = 0;
                for (final route in routeKeys) {
                  if (index == cursor) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        route,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    );
                  }
                  cursor++;

                  final chatsOnRoute = byRoute[route]!;
                  for (final chat in chatsOnRoute) {
                    if (index == cursor) {
                      return _ChatTile(chat: chat);
                    }
                    cursor++;
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(myChatsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Map<String, dynamic> chat;

  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final chatId = chat['_id']?.toString() ?? '';
    final other = chat['otherParticipant'] as Map<String, dynamic>?;
    final avatarUrl = other?['avatarUrl'];
    final showAvatar = avatarUrl != null && avatarUrl.toString().isNotEmpty;
    final verified = other?['isStudentIdVerified'] == true;
    final subtitle = chat['lastMessage']?.toString() ?? '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        backgroundImage: showAvatar
            ? NetworkImage(AppConfig.resolveMediaUrl(avatarUrl.toString()))
            : null,
        child: !showAvatar
            ? const Icon(Icons.route, color: AppTheme.primaryColor)
            : null,
      ),
      title: Text(
        other?['displayName'] ?? 'Chat',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verified ? Icons.verified : Icons.info_outline,
                size: 13,
                color: verified ? Colors.green : AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                verified ? 'Verified student' : 'Not verified yet',
                style: TextStyle(
                  fontSize: 12,
                  color: verified ? Colors.green : AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: chatId.isEmpty ? null : () => context.push('/chats/$chatId'),
    );
  }
}
