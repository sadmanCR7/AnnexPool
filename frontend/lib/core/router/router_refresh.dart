import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/providers/auth_provider.dart';

/// Notifies [GoRouter] when auth changes without recreating the router instance.
class RouterRefresh extends ChangeNotifier {
  void notifyRouter() => notifyListeners();
}

final routerRefreshProvider = Provider<RouterRefresh>((ref) {
  final refresh = RouterRefresh();
  ref.listen(authStateProvider, (_, __) => refresh.notifyRouter());
  ref.onDispose(refresh.dispose);
  return refresh;
});
