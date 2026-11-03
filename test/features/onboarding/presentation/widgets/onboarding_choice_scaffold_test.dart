import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_choice_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScaffold(WidgetTester tester, {VoidCallback? onBack}) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingChoiceScaffold(
          stepIndex: 1,
          title: 'Title',
          options: const SizedBox(height: 40),
          onContinue: () {},
          onBack: onBack,
        ),
      ),
    );
  }

  testWidgets('the back chevron has a 48-tall tap target', (tester) async {
    var backCalls = 0;
    await pumpScaffold(tester, onBack: () => backCalls++);

    final target = find.ancestor(
      of: find.byIcon(Icons.chevron_left),
      matching: find.byType(GestureDetector),
    );
    final size = tester.getSize(target);
    expect(size.height, 48);
    expect(size.width, greaterThanOrEqualTo(40));

    // A tap at the corner of the target, well outside the 24 px glyph.
    await tester.tapAt(tester.getTopLeft(target) + const Offset(2, 2));
    expect(backCalls, 1);
  });

  testWidgets('the progress bar and title sit where they do without a back '
      'chevron', (tester) async {
    await pumpScaffold(tester);
    final barWithout = tester.getCenter(find.byType(Row).first).dy;
    final titleWithout = tester.getTopLeft(find.text('Title')).dy;

    await pumpScaffold(tester, onBack: () {});
    final barWith = tester.getCenter(find.byType(Row).first).dy;
    final titleWith = tester.getTopLeft(find.text('Title')).dy;

    expect(barWith, barWithout);
    expect(titleWith, titleWithout);
  });
}
