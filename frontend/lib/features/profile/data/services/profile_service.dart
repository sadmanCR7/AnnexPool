import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class ProfileService {
  final Dio _dio;

  ProfileService(TokenStorage tokenStorage)
      : _dio = ApiClient.create(tokenStorage);

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/users/profile');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/users/profile', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    final response = await _dio.get('/users/public/$userId');
    return response.data;
  }

  Future<String> uploadAvatarBytes(
    Uint8List bytes, {
    String filename = 'avatar.jpg',
  }) async {
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    final response = await _dio.post('/users/profile/avatar', data: formData);
    return response.data['avatarUrl'] as String;
  }
}
