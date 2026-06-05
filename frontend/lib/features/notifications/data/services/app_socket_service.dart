import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/config/app_config.dart';

typedef NotificationHandler = void Function(Map<String, dynamic> payload);

class AppSocketService {
  io.Socket? _socket;
  NotificationHandler? _onNotification;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token, {required NotificationHandler onNotification}) {
    _onNotification = onNotification;
    disconnect();

    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.on('notification', (data) {
      if (data is Map) {
        _onNotification?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
