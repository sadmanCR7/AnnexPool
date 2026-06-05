import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/providers/auth_provider.dart';
import '../services/match_service.dart';

final matchServiceProvider = Provider<MatchService>((ref) {
  return MatchService(ref.watch(tokenStorageProvider));
});

class MatchQuery {
  final String source;
  final String destination;
  final String travelDate;
  final String travelTime;
  final String vehiclePreference;

  const MatchQuery({
    required this.source,
    required this.destination,
    required this.travelDate,
    required this.travelTime,
    this.vehiclePreference = 'Any',
  });
}

final matchQueryProvider = NotifierProvider<MatchQueryNotifier, MatchQuery?>(
  MatchQueryNotifier.new,
);

class MatchQueryNotifier extends Notifier<MatchQuery?> {
  @override
  MatchQuery? build() => null;

  void set(MatchQuery query) => state = query;
  void clear() => state = null;
}

final matchSuggestionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final query = ref.watch(matchQueryProvider);
  if (query == null) {
    return {'suggestions': <dynamic>[]};
  }
  final service = ref.watch(matchServiceProvider);
  return service.getSuggestions(
    source: query.source,
    destination: query.destination,
    travelDate: query.travelDate,
    travelTime: query.travelTime,
    vehiclePreference: query.vehiclePreference,
  );
});

final requestMatchesProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, requestId) async {
  final service = ref.watch(matchServiceProvider);
  return service.getMatchesForRequest(requestId);
});
