import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/config/app_config.dart';

class ChatSocketService {
  io.Socket? _socket;
  String? _activeChatId;
  String? _token;

  // Queue of [event, data] pairs to flush once connected
  final List<List<dynamic>> _pendingEmits = [];

  void Function(Map<String, dynamic>)? _onMessage;
  void Function(Map<String, dynamic>)? _onMessageSent;
  void Function(Map<String, dynamic>)? _onTyping;
  void Function(Map<String, dynamic>)? _onChatUpdated;
  void Function(String)? _onError;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token, {
    required void Function(Map<String, dynamic>) onMessage,
    required void Function(Map<String, dynamic>) onMessageSent,
    required void Function(Map<String, dynamic>) onTyping,
    void Function(Map<String, dynamic>)? onChatUpdated,
    void Function(String)? onError,
  }) {
    _token = token;
    _onMessage = onMessage;
    _onMessageSent = onMessageSent;
    _onTyping = onTyping;
    _onChatUpdated = onChatUpdated;
    _onError = onError;

    if (_socket?.connected == true) {
      return;
    }

    _socket?.dispose();
    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      // Rejoin active chat room on reconnect
      if (_activeChatId != null) {
        _socket?.emit('join_chat', {'chatId': _activeChatId});
      }
      // Flush any messages queued before connection was ready
      for (final entry in _pendingEmits) {
        _socket?.emit(entry[0] as String, entry[1]);
      }
      _pendingEmits.clear();
    });
    _socket!.on('message_received', (data) {
      _onMessage?.call(Map<String, dynamic>.from(data as Map));
    });
    _socket!.on('message_sent', (data) {
      _onMessageSent?.call(Map<String, dynamic>.from(data as Map));
    });
    _socket!.on('typing', (data) {
      _onTyping?.call(Map<String, dynamic>.from(data as Map));
    });
    _socket!.on('chat_updated', (data) {
      _onChatUpdated?.call(Map<String, dynamic>.from(data as Map));
    });
    _socket!.on('chat_error', (data) {
      if (_onError != null && data is Map) {
        _onError!(data['message']?.toString() ?? 'Chat error');
      }
    });
    _socket!.connect();
  }

  /// Emits immediately if connected, otherwise queues until connected.
  void _safeEmit(String event, dynamic data) {
    if (isConnected) {
      _socket?.emit(event, data);
    } else {
      _pendingEmits.add([event, data]);
    }
  }

  void joinChat(String chatId) {
    if (_activeChatId != null && _activeChatId != chatId) {
      _socket?.emit('leave_chat', {'chatId': _activeChatId});
    }
    _activeChatId = chatId;
    // Use safe emit so join_chat is retried on connect if socket isn't ready
    _safeEmit('join_chat', {'chatId': chatId});
  }

  void leaveChat(String chatId) {
    _socket?.emit('leave_chat', {'chatId': chatId});
    if (_activeChatId == chatId) {
      _activeChatId = null;
    }
  }

  void sendMessage(String chatId, String content) {
    if (!isConnected && _token != null) {
      connect(
        _token!,
        onMessage: _onMessage ?? (_) {},
        onMessageSent: _onMessageSent ?? (_) {},
        onTyping: _onTyping ?? (_) {},
        onChatUpdated: _onChatUpdated,
        onError: _onError,
      );
    }
    // Queue if not connected yet; will be flushed on onConnect
    _safeEmit('send_message', {'chatId': chatId, 'content': content});
  }

  void sendTyping(String chatId, bool isTyping) {
    if (isConnected) {
      _socket?.emit(isTyping ? 'typing_start' : 'typing_stop', {'chatId': chatId});
    }
  }

  void disconnect() {
    if (_activeChatId != null) {
      leaveChat(_activeChatId!);
    }
    _pendingEmits.clear();
    _socket?.dispose();
    _socket = null;
    _activeChatId = null;
    _token = null;
  }
}
