import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class MatchService {
  final Dio _dio;

  MatchService(TokenStorage tokenStorage)
      : _dio = ApiClient.create(tokenStorage);

  Future<Map<String, dynamic>> getSuggestions({
    required String source,
    required String destination,
    required String travelDate,
    required String travelTime,
    String? vehiclePreference,
    int limit = 10,
  }) async {
    final response = await _dio.get('/rides/match', queryParameters: {
      'source': source,
      'destination': destination,
      'travelDate': travelDate,
      'travelTime': travelTime,
      if (vehiclePreference != null) 'vehiclePreference': vehiclePreference,
      'limit': limit,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMatchesForRequest(String requestId) async {
    final response = await _dio.get('/rides/match/for-request/$requestId');
    return response.data;
  }
}
