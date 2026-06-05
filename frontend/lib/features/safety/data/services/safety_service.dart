import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_errors.dart';
import '../../../../core/storage/token_storage.dart';

class SafetyService {
  final Dio _dio;

  SafetyService(TokenStorage tokenStorage) : _dio = ApiClient.create(tokenStorage);

  Future<Map<String, dynamic>> getPreferences() async {
    final response = await _dio.get('/safety/preferences');
    return response.data;
  }

  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> data) async {
    final response = await _dio.put('/safety/preferences', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> triggerSOS({
    double? latitude,
    double? longitude,
    String? locationNote,
    String? rideOfferId,
  }) async {
    try {
      final response = await _dio.post('/safety/sos', data: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locationNote != null) 'locationNote': locationNote,
        if (rideOfferId != null) 'rideOfferId': rideOfferId,
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e, 'Failed to send SOS'));
    }
  }

  Future<void> reportMisconduct({
    required String reportedUserId,
    required String reason,
    String? details,
    String? rideOfferId,
  }) async {
    await _dio.post('/safety/report', data: {
      'reportedUserId': reportedUserId,
      'reason': reason,
      if (details != null) 'details': details,
      if (rideOfferId != null) 'rideOfferId': rideOfferId,
    });
  }
}
