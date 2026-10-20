import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/localization/languages_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_event_composer_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _languages = [
  AppLanguage(code: 'en', name: 'English', nativeName: 'English'),
  AppLanguage(code: 'bo', name: 'Tibetan', nativeName: 'བོད་ཡིག'),
  AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
  AppLanguage(code: 'zh', name: 'Chinese', nativeName: '中文'),
];

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage(super.code);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, {String contentLanguage = 'bo'}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        availableContentLanguagesProvider.overrideWith(
          (ref) async => _languages,
        ),
        contentLanguageProvider.overrideWith(
          (ref) => _FixedContentLanguage(contentLanguage),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GroupEventComposerScreen(
          profile: GroupProfile(
            id: 'g1',
            title: 'Lodhen Warlord',
            socialLinks: [
              GroupProfileSocialLink(
                id: 's1',
                platform: 'youtube',
                url: 'https://youtube.com/@lodhenwarlord',
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ElevatedButton _continueButton(WidgetTester tester) {
  return tester.widget<ElevatedButton>(
    find.ancestor(
      of: find.text('Continue'),
      matching: find.byType(ElevatedButton),
    ),
  );
}

void main() {
  testWidgets('step one preselects English and the content language', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('New event'), findsOneWidget);
    expect(find.text('Step 1 of 4 · About'), findsOneWidget);
    expect(find.text('Lodhen Warlord'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('བོད་ཡིག'), findsOneWidget);
    expect(find.text('中文'), findsNothing);
  });

  testWidgets('continue waits for an event name in some language', (
    tester,
  ) async {
    await _pump(tester);

    expect(_continueButton(tester).onPressed, isNull);
    expect(find.text('Add an event name to continue'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. Wednesday group practice'),
      'Wednesday group practice',
    );
    await tester.pump();

    expect(_continueButton(tester).onPressed, isNotNull);
    expect(find.text('Add an event name to continue'), findsNothing);

    // The name belongs to the active language only.
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Wednesday group practice'), findsNothing);
    expect(_continueButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('བོད་ཡིག'));
    await tester.pumpAndSettle();
    expect(find.text('Wednesday group practice'), findsOneWidget);
  });

  testWidgets('the plus chip adds languages from the sheet', (tester) async {
    await _pump(tester);

    await tester.tap(find.byTooltip('Add language'));
    await tester.pumpAndSettle();

    expect(find.text('Event languages'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(4));

    await tester.tap(find.widgetWithText(InkWell, '中文').last);
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Event languages'), findsNothing);
    expect(find.text('中文'), findsOneWidget);
    expect(find.text('हिन्दी'), findsNothing);
  });

  testWidgets('continue moves to step two and back returns', (tester) async {
    await _pump(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. Wednesday group practice'),
      'Wednesday',
    );
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 4 · When & where'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 4 · About'), findsOneWidget);
    expect(find.text('Wednesday'), findsOneWidget);
  });

  whenWhereTests();
}

Future<void> _goToStepTwo(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'e.g. Wednesday group practice'),
    'Wednesday',
  );
  await tester.pump();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void whenWhereTests() {
  testWidgets('step two asks for a date, then a venue', (tester) async {
    await _pump(tester);
    await _goToStepTwo(tester);

    expect(find.text('Step 2 of 4 · When & where'), findsOneWidget);
    expect(find.text('Pick a date to continue'), findsOneWidget);
    expect(_continueButton(tester).onPressed, isNull);
    expect(find.text('Asia/Kolkata (IST)'), findsOneWidget);
    expect(find.text('Add venue location'), findsOneWidget);

    await tester.tap(find.text('Choose a date'));
    await tester.pumpAndSettle();
    expect(find.text('Date'), findsWidgets);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.tap(find.text('${tomorrow.day}').last);
    await tester.pumpAndSettle();

    expect(find.text('Pick a date to continue'), findsNothing);
    expect(find.text('Choose a venue to continue'), findsOneWidget);
    expect(_continueButton(tester).onPressed, isNull);
  });

  testWidgets('live format needs a valid link and offers the channel', (
    tester,
  ) async {
    await _pump(tester);
    await _goToStepTwo(tester);

    await tester.tap(find.text('Live'));
    await tester.pumpAndSettle();
    expect(find.text('Add venue location'), findsNothing);
    expect(find.text('Use channel link'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'youtube.com/… or a meeting link'),
      'meet google abc',
    );
    await tester.pump();
    expect(find.text("That doesn't look like a link yet"), findsOneWidget);

    await tester.ensureVisible(find.text('Use channel link'));
    await tester.tap(find.text('Use channel link'));
    await tester.pump();
    expect(
      find.text('https://www.youtube.com/@lodhenwarlord/live'),
      findsOneWidget,
    );
    expect(find.text('Use channel link'), findsNothing);
    expect(find.textContaining('plays inside WeBuddhist'), findsOneWidget);
  });

  testWidgets('recurring shows repeats and duration instead of multi-day', (
    tester,
  ) async {
    await _pump(tester);
    await _goToStepTwo(tester);

    await tester.tap(find.text('Recurring'));
    await tester.pumpAndSettle();

    expect(find.text('First date'), findsOneWidget);
    expect(find.text('Repeats'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);
    expect(find.text('Multi-day event'), findsNothing);

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Start time'), findsNothing);
    expect(find.text('Shown as all day on the event page.'), findsOneWidget);
  });
}
