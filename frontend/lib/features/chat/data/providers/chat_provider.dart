import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../services/chat_service.dart';
import '../services/chat_socket_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.watch(tokenStorageProvider));
});

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final service = ChatSocketService();
  ref.onDispose(() => service.disconnect());
  return service;
});

final myChatsProvider = FutureProvider<List<dynamic>>((ref) async {
  ref.watch(authStateProvider);
  final service = ref.watch(chatServiceProvider);
  return service.getMyChats();
});

final chatMessagesProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, chatId) async {
  ref.watch(authStateProvider);
  final service = ref.watch(chatServiceProvider);
  return service.getChatMessages(chatId);
});
