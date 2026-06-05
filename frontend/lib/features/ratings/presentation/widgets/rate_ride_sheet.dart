import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/rating_provider.dart';

Future<void> showRateRideSheet(
  BuildContext context,
  WidgetRef ref, {
  String? rideOfferId,
  String? rideRequestId,
  required String ratedUserId,
  String? ratedUserName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _RateRideSheet(
      rideOfferId: rideOfferId,
      rideRequestId: rideRequestId,
      ratedUserId: ratedUserId,
      ratedUserName: ratedUserName,
    ),
  );
}

class _RateRideSheet extends ConsumerStatefulWidget {
  final String? rideOfferId;
  final String? rideRequestId;
  final String ratedUserId;
  final String? ratedUserName;

  const _RateRideSheet({
    this.rideOfferId,
    this.rideRequestId,
    required this.ratedUserId,
    this.ratedUserName,
  });

  @override
  ConsumerState<_RateRideSheet> createState() => _RateRideSheetState();
}

class _RateRideSheetState extends ConsumerState<_RateRideSheet> {
  int _score = 5;
  final _reviewController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(ratingServiceProvider)
          .submitRating(
            rideOfferId: widget.rideOfferId,
            rideRequestId: widget.rideRequestId,
            ratedUserId: widget.ratedUserId,
            score: _score,
            review: _reviewController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your rating!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rate ${widget.ratedUserName ?? 'co-rider'}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                icon: Icon(
                  star <= _score ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () => setState(() => _score = star),
              );
            }),
          ),
          TextFormField(
            controller: _reviewController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Review (optional)',
              hintText: 'Share your ride experience...',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit Rating'),
          ),
        ],
      ),
    );
  }
}
