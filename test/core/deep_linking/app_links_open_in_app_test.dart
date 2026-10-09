import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/deep_linking/app_links_deep_link_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const Text('home'),
        routes: [
          GoRoute(
            path: 'events/:eventId',
            builder: (_, state) =>
                Text('event:${state.pathParameters['eventId']}'),
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('AppLinksDeepLinkService.openInApp', () {
    testWidgets('routes a first-party link tapped inside the app', (
      tester,
    ) async {
      final router = _buildTestRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final service = AppLinksDeepLinkService.instance..setRouter(router);

      final uri = Uri.parse('https://webuddhist.com/open/events/ev-1');
      expect(service.openInApp(uri), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('event:ev-1'), findsOneWidget);

      // Unlike OS-delivered links, a second tap on the same link is not
      // swallowed by the duplicate-dispatch window.
      router.pop();
      await tester.pumpAndSettle();
      expect(service.openInApp(uri), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('event:ev-1'), findsOneWidget);
    });

    testWidgets('plan links use the in-app opener, not the OS reset path', (
      tester,
    ) async {
      final router = _buildTestRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      // Not awaited: push() completes only when the route is popped.
      unawaited(router.push('/home/events/ev-9'));
      await tester.pumpAndSettle();

      var osNavigatorCalls = 0;
      String? inAppPlanId;
      int? inAppDay;
      final service =
          AppLinksDeepLinkService.instance
            ..setRouter(router)
            ..setPlanNavigator((_, __, ___) => osNavigatorCalls++)
            ..setInAppPlanNavigator((planId, dayNumber, _) {
              inAppPlanId = planId;
              inAppDay = dayNumber;
            });

      final routed = service.openInApp(
        Uri.parse('https://webuddhist.com/open/plan/plan-2/day/3'),
      );
      await tester.pumpAndSettle();

      expect(routed, isTrue);
      expect(inAppPlanId, 'plan-2');
      expect(inAppDay, 3);
      expect(osNavigatorCalls, 0);
      // The screen the link was tapped from is still there underneath.
      expect(find.text('event:ev-9'), findsOneWidget);
    });

    testWidgets('leaves third-party and shortener links to the browser', (
      tester,
    ) async {
      final router = _buildTestRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final service = AppLinksDeepLinkService.instance..setRouter(router);

      expect(service.openInApp(Uri.parse('https://pech.as/abc123')), isFalse);
      expect(
        service.openInApp(Uri.parse('https://example.com/open/x')),
        isFalse,
      );
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });
  });
}
