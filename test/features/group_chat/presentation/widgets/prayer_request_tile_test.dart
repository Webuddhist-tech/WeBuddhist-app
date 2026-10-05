import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_intention_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_prayer_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/prayer_intention_tint.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/floating_prayer_text.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/prayer_request_tile.dart';
import 'package:flutter_test/flutter_test.dart';

const _healing = ChatPrayerIntentionDTO(
  slug: 'healing',
  label: 'Healing',
  color: '#4A78C2',
);

ChatMessageDTO _prayer({
  required int count,
  required bool prayedByMe,
  int mine = 0,
  List<ChatPrayerUserDTO> recent = const [],
  ChatPrayerIntentionDTO? intention,
}) {
  return ChatMessageDTO(
    id: 'a',
    roomId: 'room-1',
    senderId: 'u1',
    senderEmail: 'u1@example.com',
    senderName: 'Tenzin',
    body: 'May all be well',
    createdAt: '2026-09-11T10:04:00+00:00',
    messageType: ChatMessageDTO.typePrayer,
    intention: intention,
    prayerCount: count,
    prayedByMe: prayedByMe,
    myPrayerCount: mine,
    recentPrayers: recent,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required int count,
  required bool prayedByMe,
  int mine = 0,
  bool isOwn = false,
  List<ChatPrayerUserDTO> recent = const [],
  ChatPrayerIntentionDTO? intention,
  VoidCallback? onPray,
  VoidCallback? onShowSupporters,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PrayerRequestTile(
          request: _prayer(
            count: count,
            prayedByMe: prayedByMe,
            mine: mine,
            recent: recent,
            intention: intention,
          ),
          displayName: 'Tenzin',
          isOwn: isOwn,
          onPray: onPray,
          onShowSupporters: onShowSupporters,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    ),
  );
}

Future<void> _pumpBody(
  WidgetTester tester,
  String body, {
  TextStyle inherited = const TextStyle(),
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DefaultTextStyle.merge(
          style: inherited,
          child: PrayerRequestTile(
            request: _prayer(count: 0, prayedByMe: false).copyWith(body: body),
            displayName: 'Tenzin',
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a short request has no show more', (tester) async {
    await _pumpBody(tester, 'May all be well');
    expect(find.text('Show more'), findsNothing);
  });

  testWidgets('a long request folds and unfolds', (tester) async {
    await _pumpBody(tester, List.filled(12, 'Line of prayer').join('\n'));
    expect(find.text('Show more'), findsOneWidget);

    await tester.tap(find.text('Show more'));
    await tester.pump();
    expect(find.text('Show less'), findsOneWidget);

    await tester.tap(find.text('Show less'));
    await tester.pump();
    expect(find.text('Show more'), findsOneWidget);
  });

  testWidgets('show more is measured in the inherited font', (tester) async {
    // Fits one line in a bare style, but the spacing the theme passes down
    // (standing in for a wider font) wraps it well past four.
    await _pumpBody(
      tester,
      List.filled(24, 'om').join(' '),
      inherited: const TextStyle(letterSpacing: 40),
    );
    expect(find.text('Show more'), findsOneWidget);
  });

  testWidgets('nobody praying yet reads Pray with no count', (tester) async {
    await _pump(tester, count: 0, prayedByMe: false);
    expect(find.text('Pray'), findsOneWidget);
    expect(find.textContaining('praying'), findsNothing);
  });

  testWidgets('others praying are counted while I still read Pray', (
    tester,
  ) async {
    await _pump(tester, count: 3, prayedByMe: false);
    expect(find.text('Pray'), findsOneWidget);
    expect(find.text('3 people are praying'), findsOneWidget);
  });

  testWidgets('once I pray the button still reads Pray with my count', (
    tester,
  ) async {
    await _pump(tester, count: 1, prayedByMe: true, mine: 3);
    expect(find.text('Pray'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('Praying'), findsNothing);
    expect(find.text('1 person is praying'), findsOneWidget);
  });

  testWidgets('a prayer with no count yet shows no badge', (tester) async {
    await _pump(tester, count: 1, prayedByMe: true);
    expect(find.text('Pray'), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('the avatar stack counts the rest as more', (tester) async {
    await _pump(
      tester,
      count: 16,
      prayedByMe: false,
      recent: const [
        ChatPrayerUserDTO(userId: 'u2', name: 'Pema'),
        ChatPrayerUserDTO(userId: 'u3', name: 'Sonam'),
        ChatPrayerUserDTO(userId: 'u4', name: 'Karma'),
      ],
    );
    expect(find.text('+13 more are praying'), findsOneWidget);
  });

  testWidgets('tapping the count on my own request opens the roster', (
    tester,
  ) async {
    var opened = false;
    await _pump(
      tester,
      count: 2,
      prayedByMe: false,
      isOwn: true,
      onShowSupporters: () => opened = true,
    );
    expect(find.byIcon(AppAssets.caretRight), findsOneWidget);
    await tester.tap(find.text('2 people are praying'));
    expect(opened, isTrue);
  });

  testWidgets('the count on someone else\'s request is not tappable', (
    tester,
  ) async {
    var opened = false;
    await _pump(
      tester,
      count: 2,
      prayedByMe: false,
      onShowSupporters: () => opened = true,
    );
    expect(find.text('2 people are praying'), findsOneWidget);
    expect(find.byIcon(AppAssets.caretRight), findsNothing);
    await tester.tap(find.text('2 people are praying'));
    expect(opened, isFalse);
  });

  testWidgets('my own request shows no pray button and waits', (
    tester,
  ) async {
    await _pump(tester, count: 0, prayedByMe: false, isOwn: true);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Pray'), findsNothing);
    expect(find.text('Waiting for the first prayer...'), findsOneWidget);
  });

  testWidgets('my own request offers Edit from its menu', (tester) async {
    var edited = false;
    await _pump(
      tester,
      count: 0,
      prayedByMe: false,
      isOwn: true,
      onEdit: () => edited = true,
    );
    await tester.tap(find.byIcon(AppAssets.dotsThree));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(edited, isTrue);
  });

  testWidgets('my own request offers Delete from its menu', (tester) async {
    var deleted = false;
    await _pump(
      tester,
      count: 0,
      prayedByMe: false,
      isOwn: true,
      onDelete: () => deleted = true,
    );
    await tester.tap(find.byIcon(AppAssets.dotsThree));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsNothing);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('a request without onEdit or onDelete has no menu', (
    tester,
  ) async {
    await _pump(tester, count: 0, prayedByMe: false);
    expect(find.byIcon(AppAssets.dotsThree), findsNothing);
  });

  testWidgets('the card takes the intention colour', (tester) async {
    await _pump(tester, count: 0, prayedByMe: false, intention: _healing);
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(PrayerRequestTile),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, prayerIntentionCardColor(_healing, false));
  });

  test('a white intention keeps its text readable', () {
    const peace = ChatPrayerIntentionDTO(
      slug: 'peace',
      label: 'Peace',
      color: '#FFFFFF',
    );
    final accent = prayerIntentionColor(peace, false);
    expect(prayerAccentTextColor(accent, false), AppColors.textPrimary);
    expect(prayerAccentOnColor(accent), AppColors.textPrimary);
    expect(prayerIntentionCardBorder(peace, false), isNot(BorderSide.none));
    expect(prayerIntentionCardBorder(peace, true), isNot(BorderSide.none));
    expect(prayerIntentionCardBorder(_healing, false), BorderSide.none);
    expect(prayerIntentionCardBorder(_healing, true), BorderSide.none);
  });

  test('dark mode keeps the hue but pulls it down to a deep shade', () {
    final dark = prayerIntentionCardColor(_healing, true);
    final hsl = HSLColor.fromColor(dark);
    expect(hsl.lightness, closeTo(0.16, 0.02));
    expect(hsl.hue, closeTo(HSLColor.fromColor(const Color(0xFF4A78C2)).hue, 2));
    expect(dark.computeLuminance(), lessThan(0.05));
  });

  test('no intention means a white card, grey on dark', () {
    expect(prayerIntentionCardColor(null, false), AppColors.surfaceWhite);
    expect(prayerIntentionCardColor(null, true), AppColors.chipBackgroundDark);
    expect(prayerIntentionCardBorder(null, false), isNot(BorderSide.none));
  });

  testWidgets('praying floats the mantra up and fades it out', (tester) async {
    var prayed = 0;
    await _pump(tester, count: 0, prayedByMe: false, onPray: () => prayed++);

    await tester.tap(find.text('Pray'));
    await tester.pump();
    expect(prayed, 1);
    expect(find.text('Om Tare Tuttare Ture Soha'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Om Tare Tuttare Ture Soha'), findsNothing);
  });

  testWidgets('praying again adds another prayer and another mantra', (
    tester,
  ) async {
    var prayed = 0;
    await _pump(
      tester,
      count: 1,
      prayedByMe: true,
      mine: 1,
      onPray: () => prayed++,
    );
    await tester.tap(find.text('Pray'));
    await tester.pump();
    expect(prayed, 1);
    expect(find.text('Om Tare Tuttare Ture Soha'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  test('the mantra follows the app language, English otherwise', () {
    expect(prayerMantraForLocale(const Locale('bo')), startsWith('ཨོཾ'));
    expect(prayerMantraForLocale(const Locale('zh')), startsWith('嗡'));
    expect(prayerMantraForLocale(const Locale('mn')), startsWith('Ом'));
    expect(prayerMantraForLocale(const Locale('hi')), startsWith('ॐ'));
    expect(prayerMantraForLocale(const Locale('ne')), startsWith('ॐ'));
    expect(prayerMantraForLocale(const Locale('fr')), 'Om Tare Tuttare Ture Soha');
  });

  test('intention hex parses with or without the hash', () {
    expect(parsePrayerIntentionColor('#4A78C2'), const Color(0xFF4A78C2));
    expect(parsePrayerIntentionColor('4a78c2'), const Color(0xFF4A78C2));
    expect(parsePrayerIntentionColor('nope'), isNull);
    expect(parsePrayerIntentionColor(null), isNull);
  });
}
