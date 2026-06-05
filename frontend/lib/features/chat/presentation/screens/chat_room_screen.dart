import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/providers/chat_provider.dart';

class ChatMessage {
  final String id;
  final String content;
  final String senderName;
  final bool isMine;
  final bool isSystem;
  final DateTime? createdAt;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderName,
    required this.isMine,
    this.isSystem = false,
    this.createdAt,
  });
}

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatRoomScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _liveMessages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  @override
  void didUpdateWidget(ChatRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      ref.read(chatSocketServiceProvider).leaveChat(oldWidget.chatId);
      setState(() {
        _liveMessages.clear();
        _isTyping = false;
      });
      ref.invalidate(chatMessagesProvider(widget.chatId));
      ref.read(chatSocketServiceProvider).joinChat(widget.chatId);
    }
  }

  bool _isForThisChat(Map<String, dynamic> data) {
    return data['chatId']?.toString() == widget.chatId;
  }

  String _incomingSenderLabel(Map<String, dynamic> data) {
    final cached = ref.read(chatMessagesProvider(widget.chatId)).value;
    final routeLabel =
        (cached?['chat'] as Map?)?['routeLabel']?.toString() ?? 'Ride chat';
    return data['senderName']?.toString() ?? routeLabel;
  }

  void _upsertLiveMessage(Map<String, dynamic> data, {required bool isMine}) {
    if (!_isForThisChat(data)) return;

    final id = data['_id']?.toString();
    if (id == null || id.isEmpty) return;

    final message = ChatMessage(
      id: id,
      content: data['content']?.toString() ?? '',
      senderName: data['isSystem'] == true
          ? 'AnnexPool'
          : isMine
          ? 'You'
          : _incomingSenderLabel(data),
      isMine: data['isSystem'] == true ? false : isMine,
      isSystem: data['isSystem'] == true,
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? ''),
    );

    setState(() {
      _liveMessages.removeWhere((m) => m.id == id);
      _liveMessages.add(message);
    });
    _scrollToBottom();
  }

  Future<void> _initSocket() async {
    final token = await ref.read(tokenStorageProvider).read();
    if (token == null) return;

    final socket = ref.read(chatSocketServiceProvider);
    socket.connect(
      token,
      onMessage: (data) {
        final myId = ref.read(authStateProvider).user?['_id']?.toString();
        if (data['senderId']?.toString() == myId) return;
        _upsertLiveMessage(data, isMine: false);
      },
      onMessageSent: (data) {
        _upsertLiveMessage(data, isMine: true);
        // Drop optimistic temp rows once the server id is known.
        setState(() {
          _liveMessages.removeWhere(
            (m) => m.isMine && m.id.length < 20 && m.content == data['content'],
          );
        });
      },
      onTyping: (data) {
        if (!_isForThisChat(data)) return;
        final user = ref.read(authStateProvider).user;
        if (data['userId']?.toString() == user?['_id']?.toString()) return;
        setState(() {
          _isTyping = data['isTyping'] == true;
        });
      },
      onChatUpdated: (data) {
        if (!_isForThisChat(data)) return;
        setState(() => _liveMessages.clear());
        ref.invalidate(chatMessagesProvider(widget.chatId));
      },
      onError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );

    socket.joinChat(widget.chatId);
  }

  List<ChatMessage> _mergeMessages(List<dynamic> history) {
    final merged = <String, ChatMessage>{};

    for (final raw in history) {
      if (raw is! Map) continue;
      final id = raw['_id']?.toString();
      if (id == null) continue;
      merged[id] = ChatMessage(
        id: id,
        content: raw['content']?.toString() ?? '',
        senderName: raw['senderName']?.toString() ?? 'User',
        isMine: raw['isSystem'] == true ? false : raw['isMine'] == true,
        isSystem: raw['isSystem'] == true,
        createdAt: DateTime.tryParse(raw['createdAt']?.toString() ?? ''),
      );
    }

    for (final live in _liveMessages) {
      merged[live.id] = live;
    }

    final list = merged.values.toList();
    list.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return at.compareTo(bt);
    });
    return list;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    ref.read(chatSocketServiceProvider).leaveChat(widget.chatId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _liveMessages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: text,
          senderName: 'You',
          isMine: true,
          isSystem: false,
          createdAt: DateTime.now(),
        ),
      );
    });

    ref.read(chatSocketServiceProvider).sendMessage(widget.chatId, text);
    _messageController.clear();
    ref.read(chatSocketServiceProvider).sendTyping(widget.chatId, false);
    _scrollToBottom();
  }

  Future<void> _showSafetyMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: AppTheme.errorColor),
              title: const Text('Report user'),
              onTap: () => Navigator.pop(ctx, 'report'),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppTheme.errorColor),
              title: const Text('Block user'),
              onTap: () => Navigator.pop(ctx, 'block'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    try {
      if (action == 'block') {
        await ref.read(chatServiceProvider).blockUser(widget.chatId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User blocked')));
          Navigator.pop(context);
        }
      } else if (action == 'report') {
        final reason = await _showReportReasonDialog();
        if (reason == null || reason.isEmpty) return;

        await ref.read(chatServiceProvider).reportUser(widget.chatId, reason);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Report submitted')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<String?> _showReportReasonDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report User'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason for reporting',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    final otherParticipant = messagesAsync.maybeWhen<Map<String, dynamic>?>(
      data: (data) => data['otherParticipant'] as Map<String, dynamic>?,
      orElse: () => null,
    );
    final chatMeta = messagesAsync.maybeWhen<Map<String, dynamic>?>(
      data: (data) => data['chat'] as Map<String, dynamic>?,
      orElse: () => null,
    );

    final otherUserId = otherParticipant?['_id'];
    final avatarUrl = otherParticipant?['avatarUrl'];
    final canViewProfile = otherParticipant?['canViewProfile'] == true;
    final isClosed = chatMeta?['isClosed'] == true;

    return Scaffold(
      appBar: AppBar(
        title: messagesAsync.maybeWhen(
          data: (data) {
            final chat = data['chat'] as Map?;
            final route = chat?['routeLabel']?.toString() ?? 'Ride chat';
            final other = data['otherParticipant'] as Map?;
            final headerTitle = other?['displayName']?.toString() ?? route;
            final verified = other?['isStudentIdVerified'] == true;

            return Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage:
                      avatarUrl != null && avatarUrl.toString().isNotEmpty
                      ? NetworkImage(
                          AppConfig.resolveMediaUrl(avatarUrl.toString()),
                        )
                      : null,
                  child: avatarUrl == null || avatarUrl.toString().isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 20,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(headerTitle, overflow: TextOverflow.ellipsis),
                      Row(
                        children: [
                          Icon(
                            verified ? Icons.verified : Icons.info_outline,
                            size: 13,
                            color: verified
                                ? Colors.green
                                : AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              verified
                                  ? 'Verified student'
                                  : 'Not verified yet',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: verified
                                    ? Colors.green
                                    : AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          orElse: () => const Text('Chat'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'View profile',
            onPressed: (otherUserId == null || !canViewProfile)
                ? null
                : () => context.push('/users/$otherUserId'),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showSafetyMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '${otherParticipant?['displayName'] ?? 'Other person'} is typing...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: messagesAsync.when(
              data: (data) {
                final history = (data['messages'] as List?) ?? [];
                final allMessages = _mergeMessages(history);

                if (allMessages.isEmpty) {
                  return const Center(
                    child: Text('Say hello to coordinate your ride'),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final msg = allMessages[index];
                    if (msg.isSystem) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            msg.content,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }
                    return Align(
                      alignment: msg.isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: msg.isMine
                              ? AppTheme.primaryColor
                              : AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: msg.isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!msg.isMine)
                              Text(
                                msg.senderName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: msg.isMine
                                      ? Colors.white70
                                      : AppTheme.primaryColor,
                                ),
                              ),
                            Text(
                              msg.content,
                              style: TextStyle(
                                color: msg.isMine
                                    ? Colors.white
                                    : AppTheme.textPrimaryColor,
                              ),
                            ),
                            if (msg.isMine)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (msg.createdAt != null)
                                      Text(
                                        '${msg.createdAt!.hour.toString().padLeft(2, '0')}:${msg.createdAt!.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      msg.id.length >= 20 ? Icons.done : Icons.access_time,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load this chat',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          ref.invalidate(chatMessagesProvider(widget.chatId));
                        },
                        child: const Text('Retry'),
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Back to messages'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: isClosed
                            ? 'Ride closed — you can still chat'
                            : 'Type a message...',
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (v) {
                        ref
                            .read(chatSocketServiceProvider)
                            .sendTyping(widget.chatId, v.isNotEmpty);
                      },
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
