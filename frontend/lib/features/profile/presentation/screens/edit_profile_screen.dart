import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _studentIdController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;
  Uint8List? _localAvatarBytes;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    _nameController = TextEditingController(text: profile?['name']);
    _phoneController = TextEditingController(text: profile?['phone']);
    _studentIdController = TextEditingController(text: profile?['studentId']);
    _avatarUrl = profile?['avatarUrl'];

    final contacts = profile?['emergencyContacts'] as List?;
    _emergencyNameController = TextEditingController(
      text: contacts != null && contacts.isNotEmpty ? contacts[0]['name'] : '',
    );
    _emergencyPhoneController = TextEditingController(
      text: contacts != null && contacts.isNotEmpty ? contacts[0]['phone'] : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final bytes = await image.readAsBytes();
      setState(() => _localAvatarBytes = bytes);

      final url = await ref.read(profileServiceProvider).uploadAvatarBytes(bytes);
      setState(() => _avatarUrl = url);
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  ImageProvider? get _avatarImage {
    if (_localAvatarBytes != null) {
      return MemoryImage(_localAvatarBytes!);
    }
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return NetworkImage(AppConfig.resolveMediaUrl(_avatarUrl));
    }
    return null;
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final data = {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'studentId': _studentIdController.text.trim(),
          'emergencyContacts': [
            {
              'name': _emergencyNameController.text.trim(),
              'phone': _emergencyPhoneController.text.trim(),
              'relation': 'Emergency Contact',
            },
          ],
        };
        await ref.read(profileServiceProvider).updateProfile(data);
        ref.invalidate(profileProvider);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.surfaceColor,
                      backgroundImage: _avatarImage,
                      child: _avatarImage == null
                          ? const Icon(Icons.person, size: 50, color: AppTheme.primaryColor)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton.filled(
                        onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                        icon: _isUploadingAvatar
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.camera_alt, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                  child: const Text('Upload profile photo'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              const Text(
                'Primary Emergency Contact',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyNameController,
                decoration: const InputDecoration(labelText: 'Contact Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyPhoneController,
                decoration: const InputDecoration(labelText: 'Contact Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
