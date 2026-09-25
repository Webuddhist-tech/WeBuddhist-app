import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/analytics/analytics_events.dart';
import 'package:flutter_pecha/core/analytics/entry_analytics.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../analytics/recording_analytics_service.dart';

GoRouter _buildTestRouter() => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (_, __) => const Text('home'),
      routes: [
        GoRoute(
          path: 'series/:seriesId',
          builder:
              (_, state) => Text('series:${state.pathParameters['seriesId']}'),
        ),
      ],
    ),
  ],
);

void main() {
  late RecordingAnalyticsService service;
  late EntryAnalytics analytics;

  setUp(() {
    service = RecordingAnalyticsService();
    analytics = EntryAnalytics(service);
  });

  testWidgets('a routed link fires deep_link_opened with its kind and id', (
    tester,
  ) async {
    final router = _buildTestRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    final routed = DeepLinkRouter.route(
      Uri.parse('https://webuddhist.com/open/series/s-1'),
      router,
      source: 'app_links',
      analytics: analytics,
    );
    await tester.pumpAndSettle();

    expect(routed, isTrue);
    expect(find.text('series:s-1'), findsOneWidget);
    expect(service.eventNames, [AnalyticsEvents.deepLinkOpened]);
    expect(service.events.single.properties, {
      'source': 'app_links',
      'route_kind': 'series',
      'target_id': 's-1',
    });
  });

  testWidgets('a plan link handed to the plan navigator still counts', (
    tester,
  ) async {
    final router = _buildTestRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    String? opened;

    DeepLinkRouter.route(
      Uri.parse('https://webuddhist.com/open/plan/p-1/day/3'),
      router,
      source: 'airbridge',
      analytics: analytics,
      planNavigator: (planId, _, __) => opened = planId,
    );

    expect(opened, 'p-1');
    expect(service.events.single.properties, {
      'source': 'airbridge',
      'route_kind': 'plan',
      'target_id': 'p-1',
    });
  });

  testWidgets('an unhandled link fires nothing', (tester) async {
    final router = _buildTestRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    final routed = DeepLinkRouter.route(
      Uri.parse('https://example.com/open/series/s-1'),
      router,
      source: 'app_links',
      analytics: analytics,
    );

    expect(routed, isFalse);
    expect(service.events, isEmpty);
  });
}
