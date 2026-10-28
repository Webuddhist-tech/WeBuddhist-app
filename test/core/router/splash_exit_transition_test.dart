import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/splash_exit_transition.dart';
import 'package:flutter_test/flutter_test.dart';

const _platforms = TargetPlatformVariant({
  TargetPlatform.android,
  TargetPlatform.iOS,
});

void main() {
  late SplashExitTransition exit;
  late ValueNotifier<List<Page<void>>> pages;

  setUp(() {
    exit = SplashExitTransition();
    pages = ValueNotifier(const []);
  });
  tearDown(() => pages.dispose());

  Widget screen(String label) =>
      ColoredBox(color: Colors.white, child: Center(child: Text(label)));

  Page<void> splashPage() => MaterialPage<void>(
    key: const ValueKey('splash'),
    child: screen('splash'),
  );

  Page<void> exitPage(String label) => SplashExitPage(
    exit: exit,
    key: ValueKey(label),
    name: label,
    child: screen(label),
  );

  Future<void> pumpHost(
    WidgetTester tester, {
    bool disableAnimations = false,
  }) async {
    pages.value = [splashPage()];
    await tester.pumpWidget(
      MaterialApp(
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: disableAnimations),
              child: child!,
            ),
        home: ValueListenableBuilder<List<Page<void>>>(
          valueListenable: pages,
          builder:
              (context, value, _) => Navigator(
                pages: value,
                onDidRemovePage: (_) {},
                observers: [exit.observer],
              ),
        ),
      ),
    );
  }

  /// What the eye sees: the product of every fade above [text].
  double opacityOf(WidgetTester tester, String text) {
    var opacity = 1.0;
    for (final fade in tester.widgetList<FadeTransition>(
      find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)),
    )) {
      opacity *= fade.opacity.value;
    }
    return opacity;
  }

  Duration durationOf(WidgetTester tester, String text) =>
      ModalRoute.of(tester.element(find.text(text)))!.transitionDuration;

  testWidgets('fades the next screen in over the still splash', (tester) async {
    await pumpHost(tester);
    final centre = tester.getCenter(find.text('splash'));

    exit.arm();
    pages.value = [exitPage('home')];
    await tester.pump();
    expect(durationOf(tester, 'home'), SplashExitTransition.duration);
    expect(opacityOf(tester, 'home'), 0);

    await tester.pump(const Duration(milliseconds: 300));
    expect(
      opacityOf(tester, 'home'),
      closeTo(SplashExitTransition.curve.transform(0.5), 0.01),
    );
    // Neither screen moves, and the splash does not fade out on its own.
    expect(tester.getCenter(find.text('home')), centre);
    expect(tester.getCenter(find.text('splash')), centre);
    expect(opacityOf(tester, 'splash'), 1);

    await tester.pump(const Duration(milliseconds: 300));
    expect(opacityOf(tester, 'home'), 1);
    // The splash goes once the fade has finished.
    await tester.pumpAndSettle();
    expect(find.text('splash'), findsNothing);
  }, variant: _platforms);

  testWidgets('keeps the fade when the page is rebuilt mid-way', (
    tester,
  ) async {
    await pumpHost(tester);
    exit.arm();
    pages.value = [exitPage('home')];
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    pages.value = [exitPage('home')];
    await tester.pump();
    expect(durationOf(tester, 'home'), SplashExitTransition.duration);
    expect(
      opacityOf(tester, 'home'),
      closeTo(SplashExitTransition.curve.transform(0.5), 0.02),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('splash'), findsNothing);
  });

  testWidgets('without arm, moves exactly like a MaterialPage', (tester) async {
    Future<(Rect, Rect, double, Duration)> midway(Page<void> next) async {
      await pumpHost(tester);
      pages.value = [next];
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final frame = (
        tester.getRect(find.text('home')),
        tester.getRect(find.text('splash')),
        opacityOf(tester, 'home'),
        durationOf(tester, 'home'),
      );
      await tester.pump(const Duration(seconds: 1));
      pages.value = const [];
      await tester.pumpWidget(const SizedBox());
      return frame;
    }

    final material = await midway(
      MaterialPage<void>(key: const ValueKey('home'), child: screen('home')),
    );
    final splashExit = await midway(exitPage('home'));
    expect(splashExit, material);
    expect(material.$4, isNot(SplashExitTransition.duration));
  }, variant: _platforms);

  testWidgets('another push first cancels the fade', (tester) async {
    await pumpHost(tester);
    exit.arm();
    pages.value = [
      MaterialPage<void>(key: const ValueKey('other'), child: screen('other')),
    ];
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    pages.value = [exitPage('home')];
    await tester.pump();
    expect(durationOf(tester, 'home'), isNot(SplashExitTransition.duration));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('fades only the first screen after the splash', (tester) async {
    await pumpHost(tester);
    exit.arm();
    pages.value = [exitPage('home')];
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    pages.value = [exitPage('home'), exitPage('next')];
    await tester.pump();
    expect(durationOf(tester, 'next'), isNot(SplashExitTransition.duration));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('cuts straight to the next screen with reduced motion', (
    tester,
  ) async {
    await pumpHost(tester, disableAnimations: true);
    exit.arm();
    pages.value = [exitPage('home')];
    await tester.pump();
    await tester.pump();
    expect(opacityOf(tester, 'home'), 1);
    expect(find.text('splash'), findsNothing);
  });
}
