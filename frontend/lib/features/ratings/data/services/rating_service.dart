import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_errors.dart';
import '../../../../core/storage/token_storage.dart';

class RatingService {
  final Dio _dio;

  RatingService(TokenStorage tokenStorage)
    : _dio = ApiClient.create(tokenStorage);

  Future<Map<String, dynamic>> submitRating({
    String? rideOfferId,
    String? rideRequestId,
    required String ratedUserId,
    required int score,
    String? review,
  }) async {
    try {
      final data = <String, dynamic>{
        'ratedUserId': ratedUserId,
        'score': score,
      };
      if (rideOfferId != null) {
        data['rideOfferId'] = rideOfferId;
      }
      if (rideRequestId != null) {
        data['rideRequestId'] = rideRequestId;
      }
      if (review != null && review.isNotEmpty) {
        data['review'] = review;
      }
      final response = await _dio.post('/ratings', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e, 'Failed to submit rating'));
    }
  }

  Future<Map<String, dynamic>> getUserRatings(String userId) async {
    final response = await _dio.get('/ratings/user/$userId');
    return response.data;
  }

  Future<Map<String, dynamic>> getPendingRating(String rideOfferId) async {
    final response = await _dio.get('/ratings/pending/$rideOfferId');
    return response.data;
  }
}
