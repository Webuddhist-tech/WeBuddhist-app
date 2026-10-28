import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/launch_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'holding_router.dart';

void main() {
  late ValueNotifier<bool> hold;
  late GoRouter router;

  Future<void> pumpRouter(WidgetTester tester, {required bool holding}) async {
    hold = ValueNotifier(holding);
    addTearDown(hold.dispose);
    router = buildHoldingRouter(
      hold,
      homeRoutes: [
        GoRoute(path: 'detail', builder: (_, __) => const Text('detail')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('navigates at once when the splash has already gone', (
    tester,
  ) async {
    await pumpRouter(tester, holding: false);
    var runs = 0;
    expect(runWhenOffSplash(router, () => runs++), isTrue);
    expect(runs, 1);
  });

  testWidgets('waits out the splash hold, then lands on top of home', (
    tester,
  ) async {
    await pumpRouter(tester, holding: true);
    expect(find.text('splash'), findsOneWidget);

    // What a reminder tap or a link does: open a screen over home.
    final ranNow = runWhenOffSplash(router, () {
      router.go('/home');
      unawaited(router.push('/home/detail'));
    });
    await tester.pumpAndSettle();
    expect(ranNow, isFalse);
    expect(find.text('splash'), findsOneWidget);
    expect(find.text('detail'), findsNothing);

    hold.value = false;
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);

    // Back returns to home, not to the splash.
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(find.text('splash'), findsNothing);
  });

  testWidgets('runs each waiting navigation once, in order', (tester) async {
    await pumpRouter(tester, holding: true);
    final runs = <String>[];
    runWhenOffSplash(router, () => runs.add('first'));
    runWhenOffSplash(router, () => runs.add('second'));

    hold.value = false;
    await tester.pumpAndSettle();
    expect(runs, ['first', 'second']);

    router.go('/home/detail');
    await tester.pumpAndSettle();
    expect(runs, ['first', 'second']);
  });
}
