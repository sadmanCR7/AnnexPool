import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

String dioErrorMessage(DioException e, String fallback) {
  if (kDebugMode) {
    print('🔴 DioException Type: ${e.type}');
    print('🔴 DioException Message: ${e.message}');
    print('🔴 DioException URI: ${e.requestOptions.uri}');
    print('🔴 DioException Response Status: ${e.response?.statusCode}');
    print('🔴 Full Error: $e');
  }

  final data = e.response?.data;
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }
  if (data is String && data.isNotEmpty) {
    return data;
  }

  switch (e.type) {
    case DioExceptionType.connectionError:
      return 'Connection Error: ${e.message ?? "Cannot connect to server"}. Backend: https://annexpool-backend.onrender.com';
    case DioExceptionType.connectionTimeout:
      return 'Connection Timeout (30s). Backend may be slow or unreachable.';
    case DioExceptionType.receiveTimeout:
      return 'Server took too long to respond (30s timeout).';
    default:
      return fallback;
  }
}
