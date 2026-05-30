import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      ref.read(profileProvider.notifier).updateProfile(photo: pickedFile);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);

    if (profileState.isLoading && profileState.userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profileState.error != null && profileState.userData == null) {
      return Scaffold(body: Center(child: Text(profileState.error!)));
    }

    // ✨ FIX: Safe fallback data to prevent null crashes
    final user = profileState.userData ?? {};

    // ✨ FIX: Automatically choose localhost for Web, and 10.0.2.2 for Android
    String? photoUrl;
    if (user['profilePhoto'] != null &&
        user['profilePhoto'].toString().isNotEmpty) {
      final baseUrl = kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000';
      photoUrl = '$baseUrl${user['profilePhoto']}';
    }

    // ✨ FIX: Strict null checking before rendering Text widgets
    final String name = user['name'] ?? 'Unknown';
    final String email = user['email'] ?? 'Unknown';
    final String role = user['role']?.toString().toUpperCase() ?? 'RIDER';
    final String phone = (user['phone'] == null || user['phone'] == '')
        ? 'Not set'
        : user['phone'];

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.surface,
                    backgroundImage: photoUrl != null
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.textSecondary,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () => _pickImage(ref),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfileItem(Icons.person_outline, 'Name', name),
                    const Divider(),
                    _buildProfileItem(Icons.email_outlined, 'BUP Email', email),
                    const Divider(),
                    _buildProfileItem(Icons.badge_outlined, 'Role', role),
                    const Divider(),
                    _buildProfileItem(Icons.phone_outlined, 'Phone', phone),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
