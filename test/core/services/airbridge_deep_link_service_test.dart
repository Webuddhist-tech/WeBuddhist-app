import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/services/airbridge_deep_link_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../router/holding_router.dart';

void main() {
  testWidgets('a link that arrives while the splash holds opens after it', (
    tester,
  ) async {
    final hold = ValueNotifier(true);
    addTearDown(hold.dispose);
    final router = buildHoldingRouter(
      hold,
      routes: [
        GoRoute(path: '/practice', builder: (_, __) => const Text('practice')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    AirbridgeDeepLinkService.setRouter(router);
    AirbridgeDeepLinkService.storePendingDeepLink('webuddhist://practice');
    await tester.pumpAndSettle();
    expect(find.text('splash'), findsOneWidget);

    hold.value = false;
    await tester.pumpAndSettle();
    expect(find.text('practice'), findsOneWidget);
  });
}
