import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/auth/data/providers/auth_provider.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/profile/presentation/screens/edit_profile_screen.dart';
import 'features/profile/presentation/screens/public_profile_screen.dart';
import 'features/rides/presentation/screens/ride_listing_screen.dart';
import 'features/rides/presentation/screens/create_ride_request_screen.dart';
import 'features/rides/presentation/screens/create_ride_offer_screen.dart';
import 'features/rides/presentation/screens/my_requests_screen.dart';
import 'features/rides/presentation/screens/driver_dashboard_screen.dart';
import 'features/matching/presentation/screens/smart_matches_screen.dart';
import 'features/chat/presentation/screens/chats_list_screen.dart';
import 'features/chat/presentation/screens/chat_room_screen.dart';
import 'core/layout/main_layout.dart';
import 'core/router/router_refresh.dart';
import 'features/safety/presentation/screens/safety_center_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/notifications/data/providers/notification_provider.dart';
import 'core/layout/admin_layout.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'features/admin/presentation/screens/admin_users_screen.dart';
import 'features/admin/presentation/screens/admin_reports_screen.dart';
import 'features/admin/presentation/screens/admin_rides_screen.dart';

bool _isAdmin(Map<String, dynamic>? user) => user?['role'] == 'Admin';

String _homeForUser(Map<String, dynamic>? user) => _isAdmin(user) ? '/admin' : '/rides';

void main() {
  runApp(
    const ProviderScope(
      child: AnnexPoolApp(),
    ),
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: refresh,
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final isLoggedIn = auth.user != null;
      final path = state.matchedLocation;
      final isAuthRoute = path == '/login' || path == '/signup';
      final isSplash = path == '/splash';

      if (isSplash) return null;

      final isAdmin = _isAdmin(auth.user);

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return _homeForUser(auth.user);
      if (isLoggedIn && isAdmin && !path.startsWith('/admin') && !path.startsWith('/users')) return '/admin';
      if (isLoggedIn && !isAdmin && path.startsWith('/admin')) return '/rides';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AdminLayout(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (context, state) => const AdminReportsScreen(),
          ),
          GoRoute(
            path: '/admin/rides',
            builder: (context, state) => const AdminRidesScreen(),
          ),
        ],
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/rides',
            builder: (context, state) => const RideListingScreen(),
            routes: [
              GoRoute(
                path: 'create',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CreateRideRequestScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/my-requests',
            builder: (context, state) => const MyRequestsScreen(),
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const ChatsListScreen(),
          ),
          GoRoute(
            path: '/matches',
            builder: (context, state) => const SmartMatchesScreen(),
          ),
          GoRoute(
            path: '/driver',
            builder: (context, state) => const DriverDashboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/safety',
            builder: (context, state) => const SafetyCenterScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/offers/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateRideOfferScreen(),
      ),
      GoRoute(
        path: '/chats/:chatId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ChatRoomScreen(
          key: ValueKey(state.pathParameters['chatId']),
          chatId: state.pathParameters['chatId']!,
        ),
      ),
      GoRoute(
        path: '/users/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PublicProfileScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
    ],
  );
});

class AnnexPoolApp extends ConsumerWidget {
  const AnnexPoolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final auth = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);

    if (auth.user != null && !_isAdmin(auth.user)) {
      ref.watch(notificationBootstrapProvider);
    }

    return MaterialApp.router(
      title: 'AnnexPool',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_started) return;
    _started = true;

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final restored = await ref.read(authStateProvider.notifier).restoreSession();
    if (!mounted) return;

    final user = ref.read(authStateProvider).user;
    context.go(restored ? _homeForUser(user) : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_car,
                size: 80,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AnnexPool',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'BUP Ride Sharing Ecosystem',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
