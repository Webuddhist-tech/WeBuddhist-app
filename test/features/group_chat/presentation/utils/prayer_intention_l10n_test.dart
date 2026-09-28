import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/l10n/tolgee/tolgee_bridge.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/prayer_intention_l10n.dart';
import 'package:flutter_test/flutter_test.dart';

const _healing = ChatPrayerIntentionDTO(
  slug: 'healing',
  label: 'Healing',
  color: '#4A78C2',
  description: 'For illness and recovery.',
);

Future<BuildContext> _context(WidgetTester tester, Locale locale) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  setUp(TolgeeBridge.reset);
  tearDown(TolgeeBridge.reset);

  testWidgets('backend text is the default when Tolgee has nothing', (
    tester,
  ) async {
    final context = await _context(tester, const Locale('en'));
    expect(_healing.localizedLabel(context), 'Healing');
    expect(_healing.localizedDescription(context), 'For illness and recovery.');
  });

  testWidgets('backend text is the Tolgee key when a translation exists', (
    tester,
  ) async {
    TolgeeBridge.load(
      languageCode: 'zh',
      strings: const {'Healing': '療癒', 'For illness and recovery.': '為疾病與康復。'},
    );
    final context = await _context(tester, const Locale('zh'));
    expect(_healing.localizedLabel(context), '療癒');
    expect(_healing.localizedDescription(context), '為疾病與康復。');
  });

  testWidgets('a payload for another language is not served', (tester) async {
    TolgeeBridge.load(languageCode: 'zh', strings: const {'Healing': '療癒'});
    final context = await _context(tester, const Locale('en'));
    expect(_healing.localizedLabel(context), 'Healing');
  });
}
