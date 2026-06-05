import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class RideRequestService {
  final Dio _dio;

  RideRequestService(TokenStorage tokenStorage)
    : _dio = ApiClient.create(tokenStorage);

  Future<List<dynamic>> getRideRequests({
    String? source,
    String? destination,
    String? vehiclePreference,
  }) async {
    final response = await _dio.get(
      '/rides/requests',
      queryParameters: {
        if (source != null && source.isNotEmpty) 'source': source,
        if (destination != null && destination.isNotEmpty)
          'destination': destination,
        if (vehiclePreference != null && vehiclePreference != 'Any')
          'vehiclePreference': vehiclePreference,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getMyRideRequests() async {
    final response = await _dio.get('/rides/requests/mine');
    return response.data;
  }

  Future<Map<String, dynamic>> createRideRequest(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/rides/requests', data: data);
    return response.data;
  }

  Future<void> cancelRideRequest(String id) async {
    await _dio.put('/rides/requests/$id/cancel');
  }

  Future<void> handleResponderRequest(
    String requestId,
    String responderId,
    String action,
  ) async {
    await _dio.put(
      '/rides/requests/$requestId/responders/$responderId',
      data: {'action': action},
    );
  }

  Future<void> completeRideRequest(String id) async {
    await _dio.put('/rides/requests/$id/complete');
  }

  Future<List<dynamic>> getMyRespondedRequests() async {
    final response = await _dio.get('/rides/requests/responded');
    return response.data;
  }
}
