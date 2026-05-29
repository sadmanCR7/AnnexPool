import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text('AnnexPool: Initialization Successful', style: TextStyle(color: Color(0xFF0A2540))),
        ),
      ),
    ),
  ],
);