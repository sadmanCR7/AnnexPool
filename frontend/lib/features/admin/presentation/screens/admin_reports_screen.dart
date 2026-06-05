import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/providers/admin_provider.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminReportsProvider);

    return reportsAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return const Center(child: Text('No reports'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminReportsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final r = reports[index];
              final reporter = r['reporter'];
              final reported = r['reportedUser'];
              final pending = r['status'] == 'Pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(r['status'] ?? 'Pending'),
                            backgroundColor: pending ? Colors.orange.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                          ),
                          if (pending)
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    if (reported is Map && reported['_id'] != null) {
                                      try {
                                        await ref.read(adminServiceProvider).banUser(reported['_id'].toString(), true);
                                        await ref.read(adminServiceProvider).reviewReport(r['_id']);
                                        ref.invalidate(adminReportsProvider);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('User banned and report reviewed')),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                        }
                                      }
                                    }
                                  },
                                  child: const Text('Ban & Review', style: TextStyle(color: AppTheme.errorColor)),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await ref.read(adminServiceProvider).reviewReport(r['_id']);
                                    ref.invalidate(adminReportsProvider);
                                  },
                                  child: const Text('Mark reviewed'),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Reason: ${r['reason']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (r['details'] != null) Text(r['details']),
                      const SizedBox(height: 8),
                      Text('Reporter: ${reporter is Map ? reporter['name'] : '—'}'),
                      Text('Reported: ${reported is Map ? reported['name'] : '—'}', style: const TextStyle(color: AppTheme.errorColor)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
