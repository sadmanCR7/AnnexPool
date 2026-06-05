import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/data/providers/auth_provider.dart';
import '../../features/safety/presentation/widgets/sos_fab.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final String location;

  const MainLayout({super.key, required this.child, required this.location});

  int _selectedIndex(bool isDriver) {
    if (location.startsWith('/rides')) return 0;
    if (location.startsWith('/my-requests')) return 1;
    if (location.startsWith('/chats')) return 2;
    if (location.startsWith('/driver')) return isDriver ? 3 : 0;
    if (location.startsWith('/profile')) return isDriver ? 4 : 3;
    if (location.startsWith('/notifications') || location.startsWith('/safety')) {
      return isDriver ? 4 : 3;
    }
    return 0;
  }

  void _onTap(int index, BuildContext context, bool isDriver) {
    if (isDriver) {
      switch (index) {
        case 0:
          context.go('/rides');
        case 1:
          context.go('/my-requests');
        case 2:
          context.go('/chats');
        case 3:
          context.go('/driver');
        case 4:
          context.go('/profile');
      }
    } else {
      switch (index) {
        case 0:
          context.go('/rides');
        case 1:
          context.go('/my-requests');
        case 2:
          context.go('/chats');
        case 3:
          context.go('/profile');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDriver = ref.watch(authStateProvider).user?['role'] == 'Driver+Rider';

    final items = isDriver
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Driving'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ];

    var index = _selectedIndex(isDriver);
    if (!isDriver && index > 3) index = 3;
    if (isDriver && index > 4) index = 4;

    return Scaffold(
      body: Stack(
        children: [
          child,
          const Positioned(
            right: 16,
            bottom: 88,
            child: SosFab(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: (i) => _onTap(i, context, isDriver),
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        items: items,
      ),
    );
  }
}
