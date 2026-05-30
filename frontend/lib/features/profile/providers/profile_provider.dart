import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});

class ProfileState {
  final bool isLoading;
  final Map<String, dynamic>? userData;
  final String? error;

  ProfileState({this.isLoading = false, this.userData, this.error});
}

class ProfileNotifier extends Notifier<ProfileState> {
  final _storage = const FlutterSecureStorage();

  @override
  ProfileState build() {
    Future.microtask(() => fetchProfile());
    return ProfileState(isLoading: true);
  }

  Future<void> fetchProfile() async {
    state = ProfileState(isLoading: true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await ApiClient.instance.get(
        '/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      state = ProfileState(isLoading: false, userData: response.data['user']);
    } catch (e) {
      state = ProfileState(error: 'Failed to load profile', isLoading: false);
    }
  }

  Future<bool> updateProfile({
    String? phone,
    String? department,
    XFile? photo,
  }) async {
    state = ProfileState(isLoading: true, userData: state.userData);
    try {
      final token = await _storage.read(key: 'jwt_token');

      final formData = FormData();
      if (phone != null) formData.fields.add(MapEntry('phone', phone));
      if (department != null)
        formData.fields.add(MapEntry('department', department));

      if (photo != null) {
        final bytes = await photo.readAsBytes();

        // Ensure the web file has a valid extension so the backend doesn't reject it
        String finalName = photo.name;
        if (!finalName.toLowerCase().contains('.jpg') &&
            !finalName.toLowerCase().contains('.png') &&
            !finalName.toLowerCase().contains('.jpeg')) {
          finalName = '$finalName.jpg';
        }

        formData.files.add(
          MapEntry(
            'photo',
            MultipartFile.fromBytes(bytes, filename: finalName),
          ),
        );
      }

      final response = await ApiClient.instance.put(
        '/profile',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      state = ProfileState(isLoading: false, userData: response.data['user']);
      return true;
    } catch (e) {
      state = ProfileState(
        error: 'Failed to update profile',
        isLoading: false,
        userData: state.userData,
      );
      return false;
    }
  }
}
