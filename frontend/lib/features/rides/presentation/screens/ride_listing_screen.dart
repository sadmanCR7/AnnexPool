import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../data/providers/ride_offer_provider.dart';
import '../../../notifications/data/providers/notification_provider.dart';
import '../../data/providers/ride_request_provider.dart';
import '../../../chat/data/providers/chat_provider.dart';

class RideListingScreen extends ConsumerStatefulWidget {
  const RideListingScreen({super.key});

  @override
  ConsumerState<RideListingScreen> createState() => _RideListingScreenState();
}

class _RideListingScreenState extends ConsumerState<RideListingScreen>
    with SingleTickerProviderStateMixin {
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

  void _showRequestFilters() {
    final filters = ref.read(rideRequestFiltersProvider);
    final sourceCtrl = TextEditingController(text: filters.source);
    final destCtrl = TextEditingController(text: filters.destination);
    var vehicle = filters.vehiclePreference;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sourceCtrl,
              decoration: const InputDecoration(labelText: 'Source contains'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: destCtrl,
              decoration: const InputDecoration(
                labelText: 'Destination contains',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: vehicle,
              decoration: const InputDecoration(labelText: 'Vehicle'),
              items: const [
                DropdownMenuItem(value: 'Any', child: Text('Any')),
                DropdownMenuItem(value: 'Car', child: Text('Car')),
                DropdownMenuItem(value: 'Bike', child: Text('Bike')),
                DropdownMenuItem(value: 'Rickshaw', child: Text('Rickshaw')),
              ],
              onChanged: (v) => vehicle = v!,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(rideRequestFiltersProvider.notifier).clear();
                      ref.invalidate(rideRequestsProvider);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(rideRequestFiltersProvider.notifier)
                          .update(
                            RideRequestFilters(
                              source: sourceCtrl.text.trim(),
                              destination: destCtrl.text.trim(),
                              vehiclePreference: vehicle,
                            ),
                          );
                      ref.invalidate(rideRequestsProvider);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferFilters() {
    final filters = ref.read(rideOfferFiltersProvider);
    final sourceCtrl = TextEditingController(text: filters.source);
    final destCtrl = TextEditingController(text: filters.destination);
    var womenOnly = filters.womenOnly;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter offers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sourceCtrl,
                decoration: const InputDecoration(labelText: 'Source contains'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destCtrl,
                decoration: const InputDecoration(
                  labelText: 'Destination contains',
                ),
              ),
              SwitchListTile(
                title: const Text('Women-only rides'),
                value: womenOnly,
                onChanged: (v) => setModalState(() => womenOnly = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(rideOfferFiltersProvider.notifier)
                      .update(
                        RideOfferFilters(
                          source: sourceCtrl.text.trim(),
                          destination: destCtrl.text.trim(),
                          womenOnly: womenOnly,
                        ),
                      );
                  ref.invalidate(rideOffersProvider);
                  Navigator.pop(ctx);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _joinOffer(String id) async {
    try {
      final result = await ref.read(rideOfferServiceProvider).joinRideOffer(id);
      ref.invalidate(rideOffersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Join request sent to driver')),
        );
        final chatId = result['chatId'];
        if (chatId != null) context.push('/chats/$chatId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final isDriver = user?['role'] == 'Driver+Rider';
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Rides'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Requests'),
            Tab(text: 'Offers'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Smart matches',
            onPressed: () => context.push('/matches'),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              if (_tabController.index == 0) {
                _showRequestFilters();
              } else {
                _showOfferFilters();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            context.go('/rides/create');
          } else if (isDriver) {
            context.go('/offers/create');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Only Driver+Rider accounts can offer rides'),
              ),
            );
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RequestsTab(onRefresh: () => ref.invalidate(rideRequestsProvider)),
          _OffersTab(
            onJoin: _joinOffer,
            onRefresh: () => ref.invalidate(rideOffersProvider),
          ),
        ],
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  final VoidCallback onRefresh;

  const _RequestsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(rideRequestsProvider);

    return ridesAsync.when(
      data: (rides) {
        if (rides.isEmpty) {
          return const Center(child: Text('No ride requests available.'));
        }
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) => _RequestCard(ride: rides[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final Map<String, dynamic> ride;

  const _RequestCard({required this.ride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rider = ride['rider'];
    final riderName = rider is Map ? rider['name'] ?? 'Student' : 'Student';
    final riderId = rider is Map ? rider['_id'] : rider;
    final riderAvatarUrl = rider is Map ? rider['avatarUrl'] : null;

    final user = ref.watch(authStateProvider).user;
    final currentUserId = user?['_id'];
    final isDriver = user?['role'] == 'Driver+Rider';
    final isExpired = ride['status'] == 'Time Exceeded';

    Future<void> handleJoinRequest(BuildContext ctx, bool isOffering) async {
      try {
        final chatService = ref.read(chatServiceProvider);
        final chat = await chatService.startChatForRequest(
          ride['_id'],
          kind: isOffering ? 'driver_offer' : 'co_rider',
        );
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                isOffering ? 'Offer sent to rider' : 'Co-rider request sent',
              ),
            ),
          );
          ctx.push('/chats/${chat['_id']}');
        }
      } catch (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(
            ctx,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${ride['source']} ➔ ${ride['destination']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(ride['status']),
                  backgroundColor: isExpired
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: isExpired ? Colors.red : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                if (riderId != null) {
                  context.push('/users/$riderId');
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: riderAvatarUrl != null
                          ? NetworkImage(
                              AppConfig.resolveMediaUrl(riderAvatarUrl),
                            )
                          : null,
                      backgroundColor: Colors.grey[200],
                      child: riderAvatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'By $riderName',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${ride['travelDate'].toString().split('T').first} · ${ride['travelTime']} · ${ride['vehiclePreference']}',
            ),
            if (currentUserId != riderId && !isExpired) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (isDriver)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.local_taxi, size: 18),
                        label: const Text('Offer Ride'),
                        onPressed: () => handleJoinRequest(context, true),
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Join as Co-rider'),
                      style: isDriver
                          ? ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                            )
                          : null,
                      onPressed: () => handleJoinRequest(context, false),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OffersTab extends ConsumerWidget {
  final Future<void> Function(String id) onJoin;
  final VoidCallback onRefresh;

  const _OffersTab({required this.onJoin, required this.onRefresh});

  Map<String, dynamic>? _myPassenger(Map<String, dynamic> offer, String? myId) {
    if (myId == null) return null;
    final passengers = (offer['passengers'] as List?) ?? [];
    for (final p in passengers) {
      if (p is! Map) continue;
      final rider = p['rider'];
      final riderId = rider is Map
          ? rider['_id']?.toString()
          : rider?.toString();
      if (riderId == myId) return p as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(rideOffersProvider);
    final currentUser = ref.watch(authStateProvider).user;
    final myId = currentUser?['_id']?.toString();
    final gender = currentUser?['gender']?.toString();
    final isVerifiedFemale = currentUser?['isVerifiedFemale'] == true;
    final isFemale = gender == 'Female' || isVerifiedFemale;

    return offersAsync.when(
      data: (offers) {
        if (offers.isEmpty) {
          return const Center(child: Text('No ride offers available.'));
        }
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              final driver = offer['driver'];
              final driverName = driver is Map
                  ? driver['name'] ?? 'Driver'
                  : 'Driver';
              final driverId = driver is Map
                  ? driver['_id']?.toString()
                  : driver?.toString();
              final driverAvatarUrl = driver is Map
                  ? driver['avatarUrl']
                  : null;
              final isOwnOffer = myId != null && driverId == myId;
              final myPassenger = _myPassenger(offer, myId);
              final myStatus = myPassenger?['status']?.toString();

              const timeoutMinutes = 15;
              final requestedAt = DateTime.tryParse(
                myPassenger?['requestedAt']?.toString() ?? '',
              );
              final requestTimedOut =
                  myStatus == 'Pending' &&
                  requestedAt != null &&
                  DateTime.now().difference(requestedAt).inMinutes >
                      timeoutMinutes;

              final offerTravelDate = DateTime.tryParse(
                offer['travelDate']?.toString() ?? '',
              );
              final offerTimeExceeded =
                  offerTravelDate != null &&
                  offerTravelDate.isBefore(DateTime.now());

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${offer['source']} ➔ ${offer['destination']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (offer['womenOnly'] == true)
                            const Chip(
                              label: Text(
                                'Women only',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          if (driverId != null) {
                            context.push('/users/$driverId');
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundImage: driverAvatarUrl != null
                                    ? NetworkImage(
                                        AppConfig.resolveMediaUrl(
                                          driverAvatarUrl,
                                        ),
                                      )
                                    : null,
                                backgroundColor: Colors.grey[200],
                                child: driverAvatarUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 16,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'By $driverName',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (driver is Map &&
                                  (driver['trustScore'] ?? 0) > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '★ ${driver['trustScore']} (${driver['ratingCount'] ?? 0})',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (driver is Map && driver['isVerifiedFemale'] == true)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Verified female driver',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ),
                      Text(
                        '${offer['travelDate'].toString().split('T').first} · ${offer['travelTime']}',
                      ),
                      Text(
                        '${offer['availableSeats']}/${offer['totalSeats']} seats · ${offer['vehicleType']} · ৳${offer['pricePerSeat']}/seat',
                      ),
                      const SizedBox(height: 12),
                      if (isOwnOffer)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Chip(
                            label: const Text(
                              'Your offer — manage in Driver Dashboard',
                            ),
                            backgroundColor: AppTheme.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        )
                      else if (myStatus != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Chip(
                                label: Text('Your request: $myStatus'),
                                backgroundColor: Colors.orange.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                              if ((myStatus == 'Pending' ||
                                      myStatus == 'Accepted') &&
                                  !requestTimedOut)
                                TextButton.icon(
                                  onPressed: () async {
                                    try {
                                      final chat = await ref
                                          .read(chatServiceProvider)
                                          .startChatForRide(offer['_id']);
                                      if (context.mounted) {
                                        context.push('/chats/${chat['_id']}');
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 18,
                                  ),
                                  label: const Text('Open chat'),
                                ),
                              if (requestTimedOut)
                                const Chip(
                                  label: Text('Request time exceeded'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                            ],
                          ),
                        )
                      else
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed:
                                (offerTimeExceeded ||
                                    (offer['availableSeats'] ?? 0) <= 0 ||
                                    (offer['womenOnly'] == true && !isFemale))
                                ? null
                                : () => onJoin(offer['_id']),
                            child: Text(
                              (offer['womenOnly'] == true && !isFemale)
                                  ? 'Women Only'
                                  : 'Request to Join',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
