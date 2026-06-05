import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class AdminService {
  final Dio _dio;

  AdminService(TokenStorage tokenStorage) : _dio = ApiClient.create(tokenStorage);

  Future<Map<String, dynamic>> getAnalytics() async {
    final response = await _dio.get('/admin/analytics');
    return response.data;
  }

  Future<List<dynamic>> getUsers({String? search, bool bannedOnly = false}) async {
    final response = await _dio.get('/admin/users', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (bannedOnly) 'banned': 'true',
    });
    return response.data;
  }

  Future<void> verifyStudent(String userId) async {
    await _dio.put('/admin/users/$userId/verify-student');
  }

  Future<void> unverifyStudent(String userId) async {
    await _dio.put('/admin/users/$userId/unverify-student');
  }

  Future<void> verifyFemale(String userId) async {
    await _dio.put('/admin/users/$userId/verify-female');
  }

  Future<void> banUser(String userId, bool ban) async {
    await _dio.put('/admin/users/$userId/ban', data: {'ban': ban});
  }

  Future<List<dynamic>> getReports({String? status}) async {
    final response = await _dio.get('/admin/reports', queryParameters: {
      if (status != null) 'status': status,
    });
    return response.data;
  }

  Future<void> reviewReport(String id) async {
    await _dio.put('/admin/reports/$id');
  }

  Future<List<dynamic>> getOffers() async {
    final response = await _dio.get('/admin/rides/offers');
    return response.data;
  }

  Future<List<dynamic>> getRequests() async {
    final response = await _dio.get('/admin/rides/requests');
    return response.data;
  }

  Future<void> cancelOffer(String id) async {
    await _dio.put('/admin/rides/offers/$id/cancel');
  }

  Future<List<dynamic>> getActiveSos() async {
    final response = await _dio.get('/admin/sos');
    return response.data;
  }

  Future<void> resolveSos(String id) async {
    await _dio.put('/admin/sos/$id/resolve');
  }
}
