import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/providers/admin_provider.dart';
import 'package:go_router/go_router.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(adminUsersProvider),
              ),
            ),
            onSubmitted: (value) {
              ref.read(adminUserSearchProvider.notifier).set(value.trim());
              ref.invalidate(adminUsersProvider);
            },
          ),
        ),
        Expanded(
          child: usersAsync.when(
            data: (users) => ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final u = users[index];
                final banned = u['isBanned'] == true;
                final verified = u['isStudentIdVerified'] == true;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    onTap: () => context.push('/users/${u['_id']}'),
                    title: Text(u['name'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${u['email']}\n${u['role']} · ID: ${u['studentId'] ?? '—'}'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            Chip(
                              label: Text(verified ? 'Verified student' : 'Not verified'),
                              backgroundColor: verified
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.orange.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                color: verified ? Colors.green : Colors.orange,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            if (u['gender'] == 'Female')
                              Chip(
                                label: Text(
                                  u['isVerifiedFemale'] == true
                                      ? 'Verified female'
                                      : 'Female (unverified)',
                                ),
                                visualDensity: VisualDensity.compact,
                                labelStyle: const TextStyle(fontSize: 11),
                              ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) => _action(context, ref, u, action),
                      itemBuilder: (_) => [
                        if (!verified)
                          const PopupMenuItem(
                            value: 'verify_student',
                            child: Text('Verify as BUP student'),
                          ),
                        if (verified)
                          const PopupMenuItem(
                            value: 'unverify_student',
                            child: Text('Remove verification'),
                          ),
                        if (u['gender'] == 'Female' && u['isVerifiedFemale'] != true)
                          const PopupMenuItem(
                            value: 'verify_female',
                            child: Text('Verify female rider'),
                          ),
                        PopupMenuItem(
                          value: banned ? 'unban' : 'ban',
                          child: Text(
                            banned ? 'Unban user' : 'Ban user',
                            style: TextStyle(color: banned ? null : AppTheme.errorColor),
                          ),
                        ),
                      ],
                    ),
                    leading: CircleAvatar(
                      backgroundColor: banned
                          ? AppTheme.errorColor.withValues(alpha: 0.2)
                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: Icon(
                        banned ? Icons.block : Icons.person,
                        color: banned ? AppTheme.errorColor : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Future<void> _action(BuildContext context, WidgetRef ref, Map u, String action) async {
    final id = u['_id'].toString();
    try {
      final service = ref.read(adminServiceProvider);
      switch (action) {
        case 'verify_student':
          await service.verifyStudent(id);
        case 'verify_female':
          await service.verifyFemale(id);
        case 'unverify_student':
          await service.unverifyStudent(id);
        case 'ban':
          await service.banUser(id, true);
        case 'unban':
          await service.banUser(id, false);
      }
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminAnalyticsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
