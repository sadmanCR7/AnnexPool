import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/profile/screens/profile_screen.dart'; // Import this

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('AnnexPool Home'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () =>
                  context.push('/profile'), // Button to open profile
            ),
          ],
        ),
        body: const Center(child: Text('Welcome! You are logged in.')),
      ),
    ),
  ],
);
