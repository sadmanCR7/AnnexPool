import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          Consumer(builder: (context, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            final isDark = themeMode == ThemeMode.dark;
            return IconButton(
              icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              onPressed: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
              },
            );
          }),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
          )
        ],
      ),
      body: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.surfaceColor,
                backgroundImage: profile['avatarUrl'] != null
                    ? NetworkImage(AppConfig.resolveMediaUrl(profile['avatarUrl']))
                    : null,
                child: profile['avatarUrl'] == null
                    ? const Icon(Icons.person, size: 50, color: AppTheme.primaryColor)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(profile['name'] ?? '', style: Theme.of(context).textTheme.titleLarge),
              Text(profile['email'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Chip(
                label: Text(profile['role'] ?? 'Rider'),
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
              if ((profile['trustScore'] ?? 0) > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Trust score: ${profile['trustScore']} (${profile['ratingCount'] ?? 0} ratings)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              _buildInfoRow(context, 'Student ID', profile['studentId'] ?? 'Not set'),
              _buildInfoRow(context, 'Verified', profile['isStudentIdVerified'] ? 'Yes' : 'No', 
                color: profile['isStudentIdVerified'] ? Colors.green : AppTheme.errorColor),
              _buildInfoRow(context, 'Phone', profile['phone'] ?? 'Not set'),
              const SizedBox(height: 32),
              if (profile['role'] == 'Driver+Rider') ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/driver'),
                    icon: const Icon(Icons.directions_car),
                    label: const Text('Driver Dashboard'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/safety'),
                  icon: const Icon(Icons.shield),
                  label: const Text('Safety Center & SOS'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications),
                  label: const Text('Notifications'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/profile/edit'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile & Emergency Contacts'),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color ?? AppTheme.textPrimaryColor)),
        ],
      ),
    );
  }
}
