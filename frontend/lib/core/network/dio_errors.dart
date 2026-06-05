import 'package:dio/dio.dart';

String dioErrorMessage(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }
  if (data is String && data.isNotEmpty) {
    return data;
  }

  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
      return 'Cannot reach server. Start the backend (npm run dev) and check your connection.';
    case DioExceptionType.receiveTimeout:
      return 'Server took too long to respond.';
    default:
      return fallback;
  }
}
