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
