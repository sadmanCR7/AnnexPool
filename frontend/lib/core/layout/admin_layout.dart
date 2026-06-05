import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/data/providers/auth_provider.dart';

class AdminLayout extends ConsumerWidget {
  final Widget child;
  final String location;

  const AdminLayout({super.key, required this.child, required this.location});

  int _index() {
    if (location.startsWith('/admin/users')) return 1;
    if (location.startsWith('/admin/reports')) return 2;
    if (location.startsWith('/admin/rides')) return 3;
    return 0;
  }

  void _onTap(int i, BuildContext context) {
    switch (i) {
      case 0:
        context.go('/admin');
      case 1:
        context.go('/admin/users');
      case 2:
        context.go('/admin/reports');
      case 3:
        context.go('/admin/rides');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AnnexPool Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index(),
        onTap: (i) => _onTap(i, context),
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Rides'),
        ],
      ),
    );
  }
}
