import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class NotificationService {
  final Dio _dio;

  NotificationService(TokenStorage tokenStorage) : _dio = ApiClient.create(tokenStorage);

  Future<List<dynamic>> getNotifications() async {
    final response = await _dio.get('/notifications');
    return response.data;
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get('/notifications/unread-count');
    return response.data['count'] as int? ?? 0;
  }

  Future<void> markAsRead(String id) async {
    await _dio.put('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.put('/notifications/read-all');
  }

  Future<void> registerFcmToken(String token) async {
    await _dio.post('/notifications/fcm-token', data: {'token': token});
  }
}
