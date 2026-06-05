import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);
    final sosAsync = ref.watch(adminSosProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminAnalyticsProvider);
        ref.invalidate(adminSosProvider);
      },
      child: analyticsAsync.when(
        data: (data) {
          final totals = data['totals'] as Map<String, dynamic>? ?? {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Platform Overview', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard('Users', '${totals['users'] ?? 0}', Icons.people),
                  _StatCard('Drivers', '${totals['drivers'] ?? 0}', Icons.directions_car),
                  _StatCard('Active Rides', '${totals['activeOffers'] ?? 0}', Icons.route),
                  _StatCard('Requests', '${totals['rideRequests'] ?? 0}', Icons.list_alt),
                  _StatCard('Pending Reports', '${totals['pendingReports'] ?? 0}', Icons.flag, highlight: (totals['pendingReports'] ?? 0) > 0),
                  _StatCard('Active SOS', '${totals['activeSos'] ?? 0}', Icons.sos, highlight: (totals['activeSos'] ?? 0) > 0, color: AppTheme.errorColor),
                  _StatCard('Banned', '${totals['bannedUsers'] ?? 0}', Icons.block),
                  _StatCard('Verified Students', '${totals['verifiedStudents'] ?? 0}', Icons.verified_user),
                ],
              ),
              const SizedBox(height: 24),
              sosAsync.when(
                data: (alerts) {
                  if (alerts.isEmpty) return const SizedBox.shrink();
                  return Card(
                    color: AppTheme.errorColor.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Active SOS Alerts', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorColor)),
                          ...alerts.map((a) {
                            final user = a['user'];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(user is Map ? user['name'] ?? 'User' : 'User'),
                              subtitle: Text(a['locationNote'] ?? 'No location note'),
                              trailing: TextButton(
                                onPressed: () async {
                                  await ref.read(adminServiceProvider).resolveSos(a['_id']);
                                  ref.invalidate(adminSosProvider);
                                  ref.invalidate(adminAnalyticsProvider);
                                },
                                child: const Text('Resolve'),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final Color? color;

  const _StatCard(this.label, this.value, this.icon, {this.highlight = false, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryColor;
    return SizedBox(
      width: 160,
      child: Card(
        elevation: highlight ? 4 : 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: c),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
