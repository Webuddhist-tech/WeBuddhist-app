import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/deep_linking/app_links_deep_link_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../router/holding_router.dart';

void main() {
  testWidgets('a link delivered while the splash holds opens after it', (
    tester,
  ) async {
    final hold = ValueNotifier(true);
    addTearDown(hold.dispose);
    final router = buildHoldingRouter(
      hold,
      homeRoutes: [
        GoRoute(
          path: 'events/:eventId',
          builder:
              (_, state) => Text('event:${state.pathParameters['eventId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    AppLinksDeepLinkService.instance
      ..setRouter(router)
      ..handleLinkForTesting(
        Uri.parse('https://webuddhist.com/open/events/ev-held'),
      );
    await tester.pumpAndSettle();
    expect(find.text('splash'), findsOneWidget);

    hold.value = false;
    await tester.pumpAndSettle();
    expect(find.text('event:ev-held'), findsOneWidget);

    // The event opens on top of home, so Back returns there.
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
