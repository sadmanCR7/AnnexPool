import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class ChatService {
  final Dio _dio;

  ChatService(TokenStorage tokenStorage)
    : _dio = ApiClient.create(tokenStorage);

  Future<List<dynamic>> getMyChats() async {
    final response = await _dio.get('/chats');
    return response.data;
  }

  Future<Map<String, dynamic>> startChatForRide(String rideOfferId) async {
    final response = await _dio.post('/chats/ride/$rideOfferId');
    return response.data;
  }

  Future<Map<String, dynamic>> startChatForRequest(
    String rideRequestId, {
    String kind = 'co_rider',
  }) async {
    final response = await _dio.post(
      '/chats/request/$rideRequestId',
      data: {'kind': kind},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> startChatAsDriver(
    String rideOfferId,
    String riderId,
  ) async {
    final response = await _dio.post('/chats/ride/$rideOfferId/rider/$riderId');
    return response.data;
  }

  Future<Map<String, dynamic>> getChatMessages(String chatId) async {
    final response = await _dio.get('/chats/$chatId/messages');
    return response.data;
  }

  Future<void> blockUser(String chatId) async {
    await _dio.post('/chats/$chatId/block');
  }

  Future<void> reportUser(
    String chatId,
    String reason, {
    String? details,
  }) async {
    final data = <String, dynamic>{'reason': reason};
    if (details != null) {
      data['details'] = details;
    }
    await _dio.post('/chats/$chatId/report', data: data);
  }

  Future<Map<String, dynamic>> revealIdentity(String chatId) async {
    final response = await _dio.put('/chats/$chatId/reveal');
    return response.data;
  }
}
