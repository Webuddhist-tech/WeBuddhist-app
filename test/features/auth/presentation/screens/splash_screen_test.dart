import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations_en.dart';
import 'package:flutter_pecha/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_pecha/features/auth/presentation/screens/splash_taglines.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('randomSplashTaglineIndex picks from the tagline list', () {
    final seen = <int>{};
    for (var i = 0; i < 200; i++) {
      seen.add(randomSplashTaglineIndex(Random(i)));
    }
    expect(seen, everyElement(inInclusiveRange(0, splashTaglines.length - 1)));
    expect(seen.length, greaterThan(1));
  });

  testWidgets('shows logo and a tagline, animating in', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(tagline: 'We Buddhists learn daily'),
      ),
    );

    final text = find.text('We Buddhists learn daily');
    expect(text, findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: text, matching: find.byType(FadeTransition)).first,
    );
    expect(fade.opacity.value, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(fade.opacity.value, 1);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('picks a tagline from the list when none is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SplashScreen(),
      ),
    );
    await tester.pump();
    final l10n = AppLocalizationsEn();
    final text = tester.widget<Text>(find.byType(Text));
    expect(
      splashTaglines.map((tagline) => tagline(l10n)),
      contains(text.data),
    );
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('does not overflow in a short viewport with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(3)),
          child: SplashScreen(
            tagline:
                'We Buddhists know that things are our own projections, not the way they look.',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
