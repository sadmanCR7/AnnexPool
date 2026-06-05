import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class RideOfferService {
  final Dio _dio;

  RideOfferService(TokenStorage tokenStorage)
    : _dio = ApiClient.create(tokenStorage);

  Future<List<dynamic>> getRideOffers({
    String? source,
    String? destination,
    bool womenOnly = false,
  }) async {
    final response = await _dio.get(
      '/rides/offers',
      queryParameters: {
        if (source != null && source.isNotEmpty) 'source': source,
        if (destination != null && destination.isNotEmpty)
          'destination': destination,
        if (womenOnly) 'womenOnly': 'true',
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getMyRideOffers() async {
    final response = await _dio.get('/rides/offers/mine');
    return response.data;
  }

  Future<List<dynamic>> getMyJoinedOffers() async {
    final response = await _dio.get('/rides/offers/joined');
    return response.data;
  }

  Future<Map<String, dynamic>> createRideOffer(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/rides/offers', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> joinRideOffer(String id) async {
    final response = await _dio.post('/rides/offers/$id/join');
    return response.data;
  }

  Future<void> handlePassengerRequest(
    String offerId,
    String passengerId,
    String action,
  ) async {
    await _dio.put(
      '/rides/offers/$offerId/passengers/$passengerId',
      data: {'action': action},
    );
  }

  Future<void> cancelRideOffer(String id) async {
    await _dio.put('/rides/offers/$id/cancel');
  }

  Future<void> completeRideOffer(String id) async {
    await _dio.put('/rides/offers/$id/complete');
  }
}
