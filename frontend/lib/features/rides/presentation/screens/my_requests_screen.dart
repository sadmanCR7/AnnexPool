import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/providers/ride_request_provider.dart';
import '../../data/providers/ride_offer_provider.dart';
import '../../../matching/data/providers/match_provider.dart';
import '../../../ratings/data/providers/rating_provider.dart';
import '../../../ratings/presentation/widgets/rate_ride_sheet.dart';
import '../../../auth/data/providers/auth_provider.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Rides & Requests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Requests'),
              Tab(text: 'Joined Rides'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.go('/rides/create'),
            ),
          ],
        ),
        body: const TabBarView(children: [_MyRequestsTab(), _JoinedRidesTab()]),
      ),
    );
  }
}

class _MyRequestsTab extends ConsumerWidget {
  const _MyRequestsTab();

  Future<void> _cancelRequest(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel request?'),
        content: const Text('This ride request will be marked as cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(rideRequestServiceProvider).cancelRideRequest(id);
      ref.invalidate(myRideRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request cancelled')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _handleResponder(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    String responderId,
    String action,
  ) async {
    try {
      await ref
          .read(rideRequestServiceProvider)
          .handleResponderRequest(requestId, responderId, action);
      ref.invalidate(myRideRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Response ${action}ed')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _completeRequest(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish this ride?'),
        content: const Text('This will mark the ride as completed. You can then review the other person.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, finish'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(rideRequestServiceProvider).completeRideRequest(id);
      ref.invalidate(myRideRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride completed!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myRideRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No ride requests yet',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/rides/create'),
                  child: const Text('Request a Ride'),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myRideRequestsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final ride = requests[index];
              bool isExpired = _isExpired(
                ride['travelDate'].toString(),
                ride['travelTime'].toString(),
              );
              String displayStatus = ride['status'];
              if (displayStatus == 'Pending' && isExpired) {
                displayStatus = 'Time Exceeded';
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
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(displayStatus),
                            backgroundColor: _statusColor(
                              displayStatus,
                            ).withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: _statusColor(displayStatus),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${ride['travelDate'].toString().split('T').first} · ${ride['travelTime']}',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Vehicle: ${ride['vehiclePreference']}'),
                      if (((ride['responders'] as List?) ?? []).isNotEmpty) ...[
                        const Divider(height: 24),
                        const Text(
                          'Responses',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...(((ride['responders'] as List?) ?? []).map((
                          response,
                        ) {
                          final responder = response['user'];
                          final responderId = responder is Map
                              ? responder['_id']?.toString()
                              : responder?.toString();
                          final name = responder is Map
                              ? responder['name']?.toString() ?? 'Student'
                              : 'Student';
                          final status =
                              response['status']?.toString() ?? 'Pending';
                          final kind = response['kind'] == 'driver_offer'
                              ? 'Driver offer'
                              : 'Co-rider request';
                          final chat = response['chat'];
                          final chatId = chat is Map
                              ? chat['_id']?.toString()
                              : chat?.toString();

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(name),
                            subtitle: Text('$kind · $status'),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  tooltip: 'Chat',
                                  onPressed: chatId == null
                                      ? null
                                      : () => context.push('/chats/$chatId'),
                                ),
                                if (status == 'Pending' &&
                                    responderId != null) ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Accept',
                                    onPressed: () => _handleResponder(
                                      context,
                                      ref,
                                      ride['_id'],
                                      responderId,
                                      'accept',
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppTheme.errorColor,
                                    ),
                                    tooltip: 'Reject',
                                    onPressed: () => _handleResponder(
                                      context,
                                      ref,
                                      ride['_id'],
                                      responderId,
                                      'reject',
                                    ),
                                  ),
                                ],
                                if (displayStatus == 'Completed' &&
                                    status == 'Accepted' &&
                                    responderId != null) ...[
                                  _RequestResponderRateButton(
                                    requestId: ride['_id'],
                                    ratedUserId: responderId,
                                    ratedUserName: name,
                                  ),
                                ],
                              ],
                            ),
                          );
                        })),
                      ],
                      if (displayStatus == 'Pending') ...[
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ref
                                          .read(matchQueryProvider.notifier)
                                          .set(
                                            MatchQuery(
                                              source: ride['source'],
                                              destination: ride['destination'],
                                              travelDate: ride['travelDate']
                                                  .toString()
                                                  .split('T')
                                                  .first,
                                              travelTime: ride['travelTime'],
                                              vehiclePreference:
                                                  ride['vehiclePreference'] ??
                                                  'Any',
                                            ),
                                          );
                                      context.push('/matches');
                                    },
                                    icon: const Icon(Icons.search, size: 18),
                                    label: const Text('Search Driver'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ref
                                          .read(
                                            rideRequestFiltersProvider.notifier,
                                          )
                                          .update(
                                            RideRequestFilters(
                                              source: ride['source'],
                                              destination: ride['destination'],
                                              vehiclePreference:
                                                  ride['vehiclePreference'] ??
                                                  'Any',
                                            ),
                                          );
                                      context.push('/rides');
                                    },
                                    icon: const Icon(Icons.group_add, size: 18),
                                    label: const Text('Co-rider'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _cancelRequest(context, ref, ride['_id']),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.errorColor,
                                side: const BorderSide(
                                  color: AppTheme.errorColor,
                                ),
                              ),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancel Request'),
                            ),
                          ],
                        ),
                      ],
                      if (displayStatus == 'Matched') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _completeRequest(context, ref, ride['_id']),
                                icon: const Icon(Icons.flag_outlined, size: 18),
                                label: const Text('Finish Ride'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _cancelRequest(context, ref, ride['_id']),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                  side: const BorderSide(
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _JoinedRidesTab extends ConsumerWidget {
  const _JoinedRidesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedOffersAsync = ref.watch(myJoinedOffersProvider);
    final respondedRequestsAsync = ref.watch(myRespondedRequestsProvider);
    final currentUserId = ref.watch(authStateProvider).user?['_id']?.toString();

    return joinedOffersAsync.when(
      data: (offers) => respondedRequestsAsync.when(
        data: (requests) {
          final joinedRequests = requests.where((req) {
            final myResponder = (req['responders'] as List?)?.firstWhere(
              (r) => (r['user'] is Map ? r['user']['_id']?.toString() : r['user']?.toString()) == currentUserId,
              orElse: () => null,
            );
            return myResponder != null && myResponder['kind'] == 'co_rider';
          }).toList();

          final combined = [
            ...offers.map((o) => {'type': 'offer', 'data': o}),
            ...joinedRequests.map((r) => {'type': 'request', 'data': r}),
          ];

          if (combined.isEmpty) {
            return const Center(child: Text('You have not joined any rides.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myJoinedOffersProvider);
              ref.invalidate(myRespondedRequestsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: combined.length,
              itemBuilder: (context, index) {
                final item = combined[index];
                if (item['type'] == 'offer') {
                  final offer = item['data'];
                  final driver = offer['driver'];
                  final driverId = driver is Map
                      ? driver['_id'].toString()
                      : driver.toString();

                  final passengers = (offer['passengers'] as List?) ?? [];
                  String myStatus = 'Pending';
                  for (final p in passengers) {
                    final riderId = p['rider'] is Map
                        ? p['rider']['_id'].toString()
                        : p['rider'].toString();
                    if (riderId == currentUserId) {
                      myStatus = p['status'] ?? 'Pending';
                      break;
                    }
                  }

                  bool isExpired = _isExpired(
                    offer['travelDate'].toString(),
                    offer['travelTime'].toString(),
                  );
                  String displayStatus = offer['status'];
                  if (displayStatus == 'Active' && isExpired) {
                    displayStatus = 'Time Exceeded';
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
                                  '${offer['source']} ➔ ${offer['destination']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  myStatus == 'Accepted' ? displayStatus : myStatus,
                                ),
                                backgroundColor:
                                    (myStatus == 'Accepted'
                                            ? _statusColor(displayStatus)
                                            : _statusColor(myStatus))
                                        .withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: myStatus == 'Accepted'
                                      ? _statusColor(displayStatus)
                                      : _statusColor(myStatus),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${offer['travelDate'].toString().split('T').first} · ${offer['travelTime']}',
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Driver: ${driver is Map ? driver['name'] : 'Unknown'}',
                          ),
                          if (displayStatus == 'Completed' &&
                              myStatus == 'Accepted') ...[
                            const SizedBox(height: 12),
                            _PassengerRateButton(
                              offerId: offer['_id'],
                              driverId: driverId,
                              driverName: driver is Map ? driver['name'] : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                } else {
                  final req = item['data'];
                  final rider = req['rider'];
                  final riderId = rider is Map ? rider['_id']?.toString() : rider?.toString();
                  final riderName = rider is Map ? rider['name'] ?? 'Student' : 'Student';

                  final myResponder = (req['responders'] as List?)?.firstWhere(
                    (r) => (r['user'] is Map ? r['user']['_id']?.toString() : r['user']?.toString()) == currentUserId,
                    orElse: () => null,
                  );
                  final myStatus = myResponder?['status']?.toString() ?? 'Pending';
                  final chatVal = myResponder?['chat'];
                  final chatId = chatVal is Map
                      ? chatVal['_id']?.toString()
                      : chatVal?.toString();

                  bool isExpired = _isExpired(
                    req['travelDate'].toString(),
                    req['travelTime'].toString(),
                  );
                  String displayStatus = req['status'];
                  if (displayStatus == 'Pending' && isExpired) {
                    displayStatus = 'Time Exceeded';
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
                                  '${req['source']} ➔ ${req['destination']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  myStatus == 'Accepted' ? displayStatus : myStatus,
                                ),
                                backgroundColor:
                                    (myStatus == 'Accepted'
                                            ? _statusColor(displayStatus)
                                            : _statusColor(myStatus))
                                        .withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: myStatus == 'Accepted'
                                      ? _statusColor(displayStatus)
                                      : _statusColor(myStatus),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${req['travelDate'].toString().split('T').first} · ${req['travelTime']}',
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Requested by: $riderName'),
                          if (myStatus == 'Accepted' || myStatus == 'Pending') ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: chatId == null
                                    ? null
                                    : () => context.push('/chats/$chatId'),
                                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                label: const Text('Open chat'),
                              ),
                            ),
                          ],
                          if (displayStatus == 'Completed' && myStatus == 'Accepted') ...[
                            const SizedBox(height: 12),
                            _RequestResponderRateButton(
                              requestId: req['_id'],
                              ratedUserId: riderId ?? '',
                              ratedUserName: riderName,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading requests: $err')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading offers: $err')),
    );
  }
}

class _PassengerRateButton extends ConsumerWidget {
  final String offerId;
  final String driverId;
  final String? driverName;

  const _PassengerRateButton({
    required this.offerId,
    required this.driverId,
    this.driverName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(ratingStatusProvider(offerId));

    return pendingAsync.when(
      data: (pending) {
        if (pending['alreadyRated'] == true) {
          return const Chip(
            label: Text('Already rated ✓'),
            backgroundColor: Colors.green,
            labelStyle: TextStyle(color: Colors.white),
          );
        }

        if (pending['canRate'] == true) {
          return Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await showRateRideSheet(
                  context,
                  ref,
                  rideOfferId: offerId,
                  ratedUserId: driverId,
                  ratedUserName: driverName,
                );
                ref.invalidate(ratingStatusProvider(offerId));
              },
              icon: const Icon(Icons.star),
              label: const Text('Rate driver'),
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'Matched':
    case 'Accepted':
    case 'Completed':
      return Colors.green;
    case 'Cancelled':
    case 'Time Exceeded':
    case 'Declined':
      return AppTheme.errorColor;
    default:
      return Colors.orange;
  }
}

bool _isExpired(String dateStr, String timeStr) {
  try {
    final dStr = dateStr.split('T').first;
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    if (parts.length > 1 && parts[1].toLowerCase() == 'pm' && hour != 12) {
      hour += 12;
    }
    if (parts.length > 1 && parts[1].toLowerCase() == 'am' && hour == 12) {
      hour = 0;
    }

    final travelDateTime = DateTime.parse(
      dStr,
    ).add(Duration(hours: hour, minutes: minute));
    return DateTime.now().isAfter(travelDateTime);
  } catch (e) {
    return false;
  }
}

class _RequestResponderRateButton extends ConsumerWidget {
  final String requestId;
  final String ratedUserId;
  final String? ratedUserName;

  const _RequestResponderRateButton({
    required this.requestId,
    required this.ratedUserId,
    this.ratedUserName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(ratingStatusProvider(requestId));

    return pendingAsync.when(
      data: (pending) {
        if (pending['alreadyRated'] == true) {
          return const Chip(
            label: Text('Rated ✓'),
            backgroundColor: Colors.green,
            labelStyle: TextStyle(color: Colors.white, fontSize: 11),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }

        if (pending['canRate'] == true) {
          return TextButton.icon(
            onPressed: () async {
              await showRateRideSheet(
                context,
                ref,
                rideRequestId: requestId,
                ratedUserId: ratedUserId,
                ratedUserName: ratedUserName,
              );
              ref.invalidate(ratingStatusProvider(requestId));
            },
            icon: const Icon(Icons.star, size: 16),
            label: const Text('Rate', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
