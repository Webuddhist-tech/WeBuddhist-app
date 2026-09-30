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

  test('keys are built from the slug', () {
    expect(prayerIntentionLabelKey('peace'), 'prayer_intention_peace_label');
    expect(
      prayerIntentionDescriptionKey('peace'),
      'prayer_intention_peace_description',
    );
    expect(prayerIntentionLabelKey('long-life_2'), isNotNull);
  });

  test('a slug outside lowercase ASCII gets no key', () {
    for (final slug in ['', 'Peace', 'peace love', 'शांति', 'peace.label']) {
      expect(prayerIntentionLabelKey(slug), isNull, reason: slug);
      expect(prayerIntentionDescriptionKey(slug), isNull, reason: slug);
    }
  });

  testWidgets('backend text is the default when Tolgee has nothing', (
    tester,
  ) async {
    final context = await _context(tester, const Locale('en'));
    expect(_healing.localizedLabel(context), 'Healing');
    expect(_healing.localizedDescription(context), 'For illness and recovery.');
  });

  testWidgets('the slug names the Tolgee keys', (tester) async {
    TolgeeBridge.load(
      languageCode: 'zh',
      strings: const {
        'prayer_intention_healing_label': '療癒',
        'prayer_intention_healing_description': '為疾病與康復。',
      },
    );
    final context = await _context(tester, const Locale('zh'));
    expect(_healing.localizedLabel(context), '療癒');
    expect(_healing.localizedDescription(context), '為疾病與康復。');
  });

  testWidgets('the English text is no longer a key', (tester) async {
    TolgeeBridge.load(
      languageCode: 'zh',
      strings: const {'Healing': '療癒', 'For illness and recovery.': '為疾病與康復。'},
    );
    final context = await _context(tester, const Locale('zh'));
    expect(_healing.localizedLabel(context), 'Healing');
    expect(_healing.localizedDescription(context), 'For illness and recovery.');
  });

  testWidgets('an empty translation falls back to the backend text', (
    tester,
  ) async {
    TolgeeBridge.load(
      languageCode: 'zh',
      strings: const {'prayer_intention_healing_label': ''},
    );
    final context = await _context(tester, const Locale('zh'));
    expect(_healing.localizedLabel(context), 'Healing');
  });

  testWidgets('an unusable slug keeps the backend text', (tester) async {
    const odd = ChatPrayerIntentionDTO(
      slug: 'Healing!',
      label: 'Healing',
      color: '#4A78C2',
    );
    TolgeeBridge.load(
      languageCode: 'zh',
      strings: const {'prayer_intention_Healing!_label': '療癒'},
    );
    final context = await _context(tester, const Locale('zh'));
    expect(odd.localizedLabel(context), 'Healing');
    expect(odd.localizedDescription(context), '');
  });

  testWidgets('a payload for another language is not served', (tester) async {
    TolgeeBridge.load(
      languageCode: 'zh',
      strings: const {'prayer_intention_healing_label': '療癒'},
    );
    final context = await _context(tester, const Locale('en'));
    expect(_healing.localizedLabel(context), 'Healing');
  });
}
