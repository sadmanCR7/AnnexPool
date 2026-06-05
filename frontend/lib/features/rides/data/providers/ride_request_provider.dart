import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/data/providers/auth_provider.dart';
import '../services/ride_request_service.dart';

final rideRequestServiceProvider = Provider<RideRequestService>((ref) {
  return RideRequestService(ref.watch(tokenStorageProvider));
});

class RideRequestFilters {
  final String source;
  final String destination;
  final String vehiclePreference;

  const RideRequestFilters({
    this.source = '',
    this.destination = '',
    this.vehiclePreference = 'Any',
  });

  RideRequestFilters copyWith({
    String? source,
    String? destination,
    String? vehiclePreference,
  }) {
    return RideRequestFilters(
      source: source ?? this.source,
      destination: destination ?? this.destination,
      vehiclePreference: vehiclePreference ?? this.vehiclePreference,
    );
  }
}

final rideRequestFiltersProvider =
    NotifierProvider<RideRequestFiltersNotifier, RideRequestFilters>(
  RideRequestFiltersNotifier.new,
);

class RideRequestFiltersNotifier extends Notifier<RideRequestFilters> {
  @override
  RideRequestFilters build() => const RideRequestFilters();

  void update(RideRequestFilters filters) => state = filters;

  void clear() => state = const RideRequestFilters();
}

final rideRequestsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.watch(rideRequestServiceProvider);
  final filters = ref.watch(rideRequestFiltersProvider);
  return service.getRideRequests(
    source: filters.source,
    destination: filters.destination,
    vehiclePreference: filters.vehiclePreference,
  );
});

final myRideRequestsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.watch(rideRequestServiceProvider);
  return service.getMyRideRequests();
});

final myRespondedRequestsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.watch(rideRequestServiceProvider);
  return service.getMyRespondedRequests();
});
