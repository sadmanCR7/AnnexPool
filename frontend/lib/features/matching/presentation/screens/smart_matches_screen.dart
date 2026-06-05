import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../../../chat/data/providers/chat_provider.dart';
import '../../../rides/data/providers/ride_offer_provider.dart';
import '../../data/providers/match_provider.dart';

class SmartMatchesScreen extends ConsumerStatefulWidget {
  const SmartMatchesScreen({super.key});

  @override
  ConsumerState<SmartMatchesScreen> createState() => _SmartMatchesScreenState();
}

class _SmartMatchesScreenState extends ConsumerState<SmartMatchesScreen> {
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  String _vehiclePreference = 'Any';

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _findMatches() {
    if (_sourceController.text.isEmpty ||
        _destinationController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fill in route and schedule to find matches'),
        ),
      );
      return;
    }

    ref
        .read(matchQueryProvider.notifier)
        .set(
          MatchQuery(
            source: _sourceController.text.trim(),
            destination: _destinationController.text.trim(),
            travelDate: _dateController.text.trim(),
            travelTime: _timeController.text.trim(),
            vehiclePreference: _vehiclePreference,
          ),
        );
    ref.invalidate(matchSuggestionsProvider);
  }

  Future<void> _joinOffer(String id) async {
    try {
      final result = await ref.read(rideOfferServiceProvider).joinRideOffer(id);
      ref.invalidate(matchSuggestionsProvider);
      if (mounted) {
        final chatId = result['chatId'];
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Join request sent!')));
        if (chatId != null) {
          context.push('/chats/$chatId');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _handleJoinRequest(String requestId, bool isOffering) async {
    try {
      final chat = await ref.read(chatServiceProvider).startChatForRequest(
            requestId,
            kind: isOffering ? 'driver_offer' : 'co_rider',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffering ? 'Offer sent to rider' : 'Co-rider request sent',
            ),
          ),
        );
        context.push('/chats/${chat['_id']}');
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
    final matchesAsync = ref.watch(matchSuggestionsProvider);
    final hasQuery = ref.watch(matchQueryProvider) != null;
    final currentUser = ref.watch(authStateProvider).user;
    final currentUserId = currentUser?['_id']?.toString();
    final isDriver = currentUser?['role'] == 'Driver+Rider';
    final gender = currentUser?['gender']?.toString();
    final isVerifiedFemale = currentUser?['isVerifiedFemale'] == true;
    final isFemale = gender == 'Female' || isVerifiedFemale;

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Matches')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _sourceController,
                  decoration: const InputDecoration(
                    labelText: 'From',
                    hintText: 'e.g. Mirpur 10',
                    prefixIcon: Icon(Icons.trip_origin),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    hintText: 'e.g. BUP Campus',
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(labelText: 'Date'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _timeController,
                        decoration: const InputDecoration(labelText: 'Time'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _vehiclePreference,
                  decoration: const InputDecoration(labelText: 'Vehicle'),
                  items: const [
                    DropdownMenuItem(value: 'Any', child: Text('Any')),
                    DropdownMenuItem(value: 'Car', child: Text('Car')),
                    DropdownMenuItem(value: 'Bike', child: Text('Bike')),
                    DropdownMenuItem(
                      value: 'Rickshaw',
                      child: Text('Rickshaw'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _vehiclePreference = v!),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _findMatches,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Find Best Matches'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: !hasQuery
                ? Center(
                    child: Text(
                      'Enter your route to get intelligent suggestions',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : matchesAsync.when(
                    data: (data) {
                      final suggestions = (data['suggestions'] as List?) ?? [];
                      if (suggestions.isEmpty) {
                        return const Center(
                          child: Text(
                            'No strong matches found. Try adjusting your route.',
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(matchSuggestionsProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            final item = suggestions[index];
                            final isOffer = item['matchType'] == 'offer';
                            final score = item['matchScore'] ?? 0;
                            final offerTravelDate = DateTime.tryParse(
                              item['travelDate']?.toString() ?? '',
                            );
                            final offerTimeExceeded =
                                offerTravelDate != null &&
                                offerTravelDate.isBefore(DateTime.now());

                            final user = isOffer ? item['driver'] : item['rider'];
                            final userName = user is Map ? user['name'] ?? 'Student' : 'Student';
                            final userId = user is Map ? user['_id']?.toString() : user?.toString();
                            final userAvatarUrl = user is Map ? user['avatarUrl'] as String? : null;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '$score% match',
                                            style: const TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Chip(
                                          label: Text(
                                            isOffer ? 'Offer' : 'Request',
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${item['source']} ➔ ${item['destination']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () {
                                        if (userId != null) {
                                          context.push('/users/$userId');
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
                                              backgroundImage: userAvatarUrl != null
                                                  ? NetworkImage(
                                                      AppConfig.resolveMediaUrl(userAvatarUrl),
                                                    )
                                                  : null,
                                              backgroundColor: Colors.grey[200],
                                              child: userAvatarUrl == null
                                                  ? const Icon(
                                                      Icons.person,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'By $userName',
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
                                      '${item['travelDate'].toString().split('T').first} · ${item['travelTime']}',
                                    ),
                                    if (isOffer) ...[
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: (offerTimeExceeded || (item['womenOnly'] == true && !isFemale))
                                            ? null
                                            : () => _joinOffer(item['_id']),
                                        child: Text(
                                          (item['womenOnly'] == true && !isFemale)
                                              ? 'Women Only'
                                              : 'Request to Join',
                                        ),
                                      ),
                                    ] else ...[
                                      if (currentUserId != userId) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            if (isDriver)
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.local_taxi, size: 18),
                                                label: const Text('Offer Ride'),
                                                onPressed: () => _handleJoinRequest(item['_id'], true),
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
                                              onPressed: () => _handleJoinRequest(item['_id'], false),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
          ),
        ],
      ),
    );
  }
}
