import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/providers/admin_provider.dart';

class AdminRidesScreen extends ConsumerStatefulWidget {
  const AdminRidesScreen({super.key});

  @override
  ConsumerState<AdminRidesScreen> createState() => _AdminRidesScreenState();
}

class _AdminRidesScreenState extends ConsumerState<AdminRidesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(adminOffersProvider);
    final requestsAsync = ref.watch(adminRequestsProvider);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          tabs: const [Tab(text: 'Offers'), Tab(text: 'Requests')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              offersAsync.when(
                data: (offers) => _buildOffers(context, ref, offers),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
              requestsAsync.when(
                data: (requests) => _buildRequests(requests),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOffers(BuildContext context, WidgetRef ref, List offers) {
    if (offers.isEmpty) return const Center(child: Text('No offers'));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminOffersProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: offers.length,
        itemBuilder: (context, i) {
          final o = offers[i];
          final driver = o['driver'];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('${o['source']} ➔ ${o['destination']}'),
              subtitle: Text(
                'Driver: ${driver is Map ? driver['name'] : '—'}\n${o['status']} · ${o['availableSeats']}/${o['totalSeats']} seats',
              ),
              isThreeLine: true,
              trailing: o['status'] == 'Active' || o['status'] == 'Full'
                  ? IconButton(
                      icon: const Icon(Icons.cancel, color: AppTheme.errorColor),
                      onPressed: () async {
                        await ref.read(adminServiceProvider).cancelOffer(o['_id']);
                        ref.invalidate(adminOffersProvider);
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequests(List requests) {
    if (requests.isEmpty) return const Center(child: Text('No requests'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final r = requests[i];
        final rider = r['rider'];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('${r['source']} ➔ ${r['destination']}'),
            subtitle: Text(
              'Rider: ${rider is Map ? rider['name'] : '—'}\n${r['status']} · ${r['travelDate'].toString().split('T').first}',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
