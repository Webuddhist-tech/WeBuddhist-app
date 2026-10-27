import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A router whose guard behaves like the app's around the launch splash:
/// while [hold] is on, every navigation is redirected to `/splash` and its
/// destination forgotten; once it is off, the splash gives way to `/home`.
GoRouter buildHoldingRouter(
  ValueNotifier<bool> hold, {
  List<RouteBase> homeRoutes = const [],
  List<RouteBase> routes = const [],
}) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: hold,
    redirect: (context, state) {
      if (hold.value) return '/splash';
      if (state.matchedLocation == '/splash') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const Text('splash')),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Text('home'),
        routes: homeRoutes,
      ),
      ...routes,
    ],
  );
}
