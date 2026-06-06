import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/providers/profile_provider.dart';

class PublicProfileScreen extends ConsumerWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: profileAsync.when(
        data: (profile) {
          final avatarUrl = profile['avatarUrl'] as String?;
          final isVerifiedStudent = profile['isStudentIdVerified'] == true;
          final isVerifiedFemale = profile['isVerifiedFemale'] == true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: AppTheme.surfaceColor,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(AppConfig.resolveMediaUrl(avatarUrl))
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 52, color: AppTheme.primaryColor)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile['name'] ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(profile['role'] ?? 'Rider'),
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        isVerifiedStudent ? 'Student ID verified' : 'Student ID not verified',
                      ),
                      backgroundColor: isVerifiedStudent
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: isVerifiedStudent ? Colors.green : AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    if (profile['gender'] == 'Female')
                      Chip(
                        label: Text(
                          isVerifiedFemale ? 'Verified female' : 'Female (unverified)',
                        ),
                        backgroundColor:
                            isVerifiedFemale ? Colors.green.withValues(alpha: 0.15) : AppTheme.surfaceColor,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if ((profile['trustScore'] ?? 0) > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Trust score: ${profile['trustScore']} (${profile['ratingCount'] ?? 0} ratings)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                _infoRow(context, 'Phone', profile['phone'] ?? '—'),
                _infoRow(context, 'Student ID', profile['studentId'] ?? '—'),
                
                if (ref.watch(authStateProvider).user?['role'] == 'Admin' && profile['emergencyContact'] != null)
                  _infoRow(
                    context, 
                    'Emergency Contact', 
                    '${profile['emergencyContact']['name'] ?? 'Unknown'} (${profile['emergencyContact']['relation'] ?? 'N/A'}) - ${profile['emergencyContact']['phone'] ?? 'No phone'}'
                  ),



              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

