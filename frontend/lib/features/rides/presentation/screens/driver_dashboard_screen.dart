import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/providers/ride_offer_provider.dart';
import '../../data/providers/ride_request_provider.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../chat/data/providers/chat_provider.dart';
import '../../../ratings/presentation/widgets/rate_ride_sheet.dart';
import '../../../ratings/data/providers/rating_provider.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  bool _showCompleted = false;

  bool _isExpired(String dateStr, String timeStr) {
    try {
      final dStr = dateStr.split('T').first;
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      if (parts.length > 1 && parts[1].toLowerCase() == 'pm' && hour != 12) hour += 12;
      if (parts.length > 1 && parts[1].toLowerCase() == 'am' && hour == 12) hour = 0;
      
      final travelDateTime = DateTime.parse(dStr).add(Duration(hours: hour, minutes: minute));
      return DateTime.now().isAfter(travelDateTime);
    } catch (e) {
      return false;
    }
  }

  Future<void> _handlePassenger(
    BuildContext context,
    WidgetRef ref,
    String offerId,
    String riderId,
    String action,
  ) async {
    try {
      await ref.read(rideOfferServiceProvider).handlePassengerRequest(
            offerId,
            riderId,
            action,
          );
      ref.invalidate(myRideOffersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passenger ${action}ed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _openChat(
    BuildContext context,
    WidgetRef ref,
    String offerId,
    String riderId,
  ) async {
    try {
      final chat = await ref.read(chatServiceProvider).startChatAsDriver(
            offerId,
            riderId,
          );
      if (context.mounted) {
        context.push('/chats/${chat['_id']}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _completeOffer(BuildContext context, WidgetRef ref, Map<String, dynamic> offer) async {
    try {
      await ref.read(rideOfferServiceProvider).completeRideOffer(offer['_id']);
      ref.invalidate(myRideOffersProvider);
      if (!context.mounted) return;

      final accepted = (offer['passengers'] as List?)
          ?.where((p) => p['status'] == 'Accepted')
          .toList();
      if (accepted != null && accepted.isNotEmpty) {
        final pending = await ref.read(ratingServiceProvider).getPendingRating(offer['_id']);
        if (pending['alreadyRated'] == true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ride completed! You already rated this ride.')),
            );
          }
          return;
        }
        if (pending['canRate'] == true && context.mounted) {
          final rider = accepted.first['rider'];
          final riderId = rider is Map ? rider['_id'].toString() : rider.toString();
          final riderName = rider is Map ? rider['name'] : null;
          await showRateRideSheet(
            context,
            ref,
            rideOfferId: offer['_id'],
            ratedUserId: riderId,
            ratedUserName: riderName,
          );
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride completed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _cancelOffer(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel ride offer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(rideOfferServiceProvider).cancelRideOffer(id);
      ref.invalidate(myRideOffersProvider);
      ref.invalidate(rideOffersProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(myRideOffersProvider);
    final respondedRequestsAsync = ref.watch(myRespondedRequestsProvider);
    final currentUserId = ref.watch(authStateProvider).user?['_id']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: Icon(_showCompleted ? Icons.visibility_off : Icons.history),
            tooltip: _showCompleted ? 'Hide completed rides' : 'Show completed rides',
            onPressed: () => setState(() => _showCompleted = !_showCompleted),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/offers/create'),
          ),
        ],
      ),
      body: offersAsync.when(
        data: (allOffers) => respondedRequestsAsync.when(
          data: (allRequests) {
            final driverRespondedRequests = allRequests.where((req) {
              final myResponder = (req['responders'] as List?)?.firstWhere(
                (r) => (r['user'] is Map ? r['user']['_id']?.toString() : r['user']?.toString()) == currentUserId,
                orElse: () => null,
              );
              return myResponder != null && myResponder['kind'] == 'driver_offer';
            }).toList();

            final offers = _showCompleted
                ? allOffers
                : allOffers
                    .where((o) => o['status'] == 'Active' || o['status'] == 'Full')
                    .toList();

            final requests = _showCompleted
                ? driverRespondedRequests
                : driverRespondedRequests
                    .where((r) => r['status'] == 'Pending' || r['status'] == 'Matched')
                    .toList();

            final combined = [
              ...offers.map((o) => {'type': 'offer', 'data': o}),
              ...requests.map((r) => {'type': 'request', 'data': r}),
            ];

            if (combined.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(_showCompleted ? 'No ride offers yet' : 'No active ride offers'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/offers/create'),
                      child: const Text('Offer a Ride'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myRideOffersProvider);
                ref.invalidate(myRespondedRequestsProvider);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: combined.length,
                itemBuilder: (context, index) {
                  final item = combined[index];
                  if (item['type'] == 'offer') {
                    final offer = item['data'];
                    final passengers = (offer['passengers'] as List?) ?? [];
                    final pending = passengers.where((p) => p['status'] == 'Pending').toList();
                    final accepted = passengers.where((p) => p['status'] == 'Accepted').toList();
                    
                    bool isExpired = _isExpired(offer['travelDate'].toString(), offer['travelTime'].toString());
                    String displayStatus = offer['status'];
                    if ((displayStatus == 'Active' || displayStatus == 'Full') && isExpired) {
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Chip(
                                  label: Text(displayStatus),
                                  backgroundColor: displayStatus == 'Time Exceeded' ? AppTheme.errorColor.withValues(alpha: 0.15) : null,
                                  labelStyle: displayStatus == 'Time Exceeded' ? const TextStyle(color: AppTheme.errorColor) : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${offer['travelDate'].toString().split('T').first} · ${offer['travelTime']}',
                            ),
                            Text(
                              'Seats: ${offer['availableSeats']}/${offer['totalSeats']} · ${offer['vehicleType']}',
                            ),
                            if (offer['status'] == 'Active' || offer['status'] == 'Full') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => _completeOffer(context, ref, offer),
                                    child: const Text('Mark completed'),
                                  ),
                                  TextButton(
                                    onPressed: () => _cancelOffer(context, ref, offer['_id']),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: AppTheme.errorColor),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (offer['status'] == 'Completed' && accepted.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _RateButton(offerId: offer['_id'], accepted: accepted),
                            ],
                            if (pending.isNotEmpty) ...[
                              const Divider(height: 24),
                              const Text(
                                'Pending join requests',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...pending.map((p) {
                                final rider = p['rider'];
                                final riderId = rider is Map ? rider['_id'].toString() : rider.toString();
                                final name = rider is Map ? rider['name'] ?? 'Co-rider' : 'Co-rider';
                                const timeoutMinutes = 15;
                                final requestedAt = DateTime.tryParse(p['requestedAt']?.toString() ?? '');
                                final requestTimedOut = requestedAt != null &&
                                    DateTime.now().difference(requestedAt).inMinutes > timeoutMinutes;
                                return Card(
                                  margin: const EdgeInsets.only(top: 8),
                                  color: AppTheme.surfaceColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        if (requestTimedOut) ...[
                                          const SizedBox(height: 8),
                                          Chip(
                                            label: const Text('Request time exceeded'),
                                            backgroundColor: AppTheme.errorColor.withValues(alpha: 0.15),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                                label: const Text('Chat'),
                                                onPressed: requestTimedOut
                                                    ? null
                                                    : () => _openChat(
                                                  context,
                                                  ref,
                                                  offer['_id'],
                                                  riderId,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.check, color: Colors.green),
                                              tooltip: 'Accept',
                                              onPressed: requestTimedOut
                                                  ? null
                                                  : () => _handlePassenger(
                                                        context,
                                                        ref,
                                                        offer['_id'],
                                                        riderId,
                                                        'accept',
                                                      ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, color: AppTheme.errorColor),
                                              tooltip: 'Reject',
                                              onPressed: requestTimedOut
                                                  ? null
                                                  : () => _handlePassenger(
                                                        context,
                                                        ref,
                                                        offer['_id'],
                                                        riderId,
                                                        'reject',
                                                      ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                            if (accepted.isNotEmpty &&
                                (offer['status'] == 'Active' || offer['status'] == 'Full')) ...[
                              const Divider(height: 24),
                              const Text(
                                'Accepted passengers',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...accepted.map((p) {
                                final rider = p['rider'];
                                final riderId = rider is Map ? rider['_id'].toString() : rider.toString();
                                final name = rider is Map ? rider['name'] ?? 'Co-rider' : 'Co-rider';
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(name),
                                  trailing: TextButton.icon(
                                    icon: const Icon(Icons.chat, size: 18),
                                    label: const Text('Chat'),
                                    onPressed: () => _openChat(
                                      context,
                                      ref,
                                      offer['_id'],
                                      riderId,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    );
                  } else {
                    // It is a ride request where the driver responded as driver_offer
                    final req = item['data'];
                    final rider = req['rider'];
                    final riderName = rider is Map ? rider['name']?.toString() ?? 'Rider' : 'Rider';
                    final riderId = rider is Map ? rider['_id']?.toString() : rider?.toString();

                    final myResponder = (req['responders'] as List?)?.firstWhere(
                      (r) => (r['user'] is Map ? r['user']['_id']?.toString() : r['user']?.toString()) == currentUserId,
                      orElse: () => null,
                    );
                    final myStatus = myResponder?['status'] ?? 'Pending';
                    final chatId = myResponder?['chat'] is Map
                        ? myResponder['chat']['_id']?.toString()
                        : myResponder?['chat']?.toString();

                    bool isExpired = _isExpired(req['travelDate'].toString(), req['travelTime'].toString());
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Chip(
                                  label: Text(myStatus == 'Accepted' ? 'Ride: $displayStatus' : 'Offer: $myStatus'),
                                  backgroundColor: myStatus == 'Rejected' ? AppTheme.errorColor.withValues(alpha: 0.15) : null,
                                  labelStyle: myStatus == 'Rejected' ? const TextStyle(color: AppTheme.errorColor) : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${req['travelDate'].toString().split('T').first} · ${req['travelTime']}',
                            ),
                            Text(
                              'Rider: $riderName · Preference: ${req['vehiclePreference']}',
                            ),
                            if (myStatus == 'Accepted' && req['status'] != 'Completed') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.chat, size: 18),
                                    label: const Text('Chat'),
                                    onPressed: chatId == null
                                        ? null
                                        : () => context.push('/chats/$chatId'),
                                  ),
                                ],
                              ),
                            ] else if (myStatus == 'Pending') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                    label: const Text('Chat'),
                                    onPressed: chatId == null
                                        ? null
                                        : () => context.push('/chats/$chatId'),
                                  ),
                                ],
                              ),
                            ],
                            if (req['status'] == 'Completed' && myStatus == 'Accepted' && riderId != null) ...[
                              const SizedBox(height: 8),
                              _RequestRateButton(
                                requestId: req['_id'],
                                riderId: riderId,
                                riderName: riderName,
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
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _RateButton extends ConsumerWidget {
  final String offerId;
  final List<dynamic> accepted;

  const _RateButton({required this.offerId, required this.accepted});

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
          return TextButton.icon(
            onPressed: () async {
              if (accepted.isEmpty) return;
              final rider = accepted.first['rider'];
              await showRateRideSheet(
                context,
                ref,
                rideOfferId: offerId,
                ratedUserId: rider is Map ? rider['_id'].toString() : rider.toString(),
                ratedUserName: rider is Map ? rider['name'] : null,
              );
              ref.invalidate(ratingStatusProvider(offerId));
            },
            icon: const Icon(Icons.star),
            label: const Text('Rate passenger'),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _RequestRateButton extends ConsumerWidget {
  final String requestId;
  final String riderId;
  final String? riderName;

  const _RequestRateButton({
    required this.requestId,
    required this.riderId,
    this.riderName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(ratingStatusProvider(requestId));
    
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
          return TextButton.icon(
            onPressed: () async {
              await showRateRideSheet(
                context,
                ref,
                rideRequestId: requestId,
                ratedUserId: riderId,
                ratedUserName: riderName,
              );
              ref.invalidate(ratingStatusProvider(requestId));
            },
            icon: const Icon(Icons.star),
            label: const Text('Rate rider'),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
