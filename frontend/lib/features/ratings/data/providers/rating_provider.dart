import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../services/rating_service.dart';

final ratingServiceProvider = Provider<RatingService>((ref) {
  return RatingService(ref.watch(tokenStorageProvider));
});

final userRatingsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  return ref.watch(ratingServiceProvider).getUserRatings(userId);
});

final ratingStatusProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, rideOfferId) async {
  return ref.watch(ratingServiceProvider).getPendingRating(rideOfferId);
});
