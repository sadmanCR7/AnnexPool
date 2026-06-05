import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../services/ride_offer_service.dart';

final rideOfferServiceProvider = Provider<RideOfferService>((ref) {
  return RideOfferService(ref.watch(tokenStorageProvider));
});

class RideOfferFilters {
  final String source;
  final String destination;
  final bool womenOnly;

  const RideOfferFilters({
    this.source = '',
    this.destination = '',
    this.womenOnly = false,
  });

  RideOfferFilters copyWith({
    String? source,
    String? destination,
    bool? womenOnly,
  }) {
    return RideOfferFilters(
      source: source ?? this.source,
      destination: destination ?? this.destination,
      womenOnly: womenOnly ?? this.womenOnly,
    );
  }
}

final rideOfferFiltersProvider =
    NotifierProvider<RideOfferFiltersNotifier, RideOfferFilters>(
  RideOfferFiltersNotifier.new,
);

class RideOfferFiltersNotifier extends Notifier<RideOfferFilters> {
  @override
  RideOfferFilters build() => const RideOfferFilters();

  void update(RideOfferFilters filters) => state = filters;

  void clear() => state = const RideOfferFilters();
}

final rideOffersProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.watch(rideOfferServiceProvider);
  final filters = ref.watch(rideOfferFiltersProvider);
  return service.getRideOffers(
    source: filters.source,
    destination: filters.destination,
    womenOnly: filters.womenOnly,
  );
});

final myRideOffersProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.watch(rideOfferServiceProvider);
  return service.getMyRideOffers();
});

final myJoinedOffersProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.watch(rideOfferServiceProvider);
  return service.getMyJoinedOffers();
});
