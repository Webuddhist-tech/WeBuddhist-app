import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/interlinear_segment_item.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_verse_frame.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/segment_item.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_pecha/features/texts/presentation/segment_html_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_storage.dart';

const _scope = ReaderSettingsScope(
  textId: 'S',
  context: ReaderLayoutContext.library,
);

// Tibetan lines and Tibetan numerals use bundled fonts: no downloads.
const _segment = Segment(
  segmentId: 'S-12',
  segmentNumber: 12,
  content: 'ཀ་ཁ་ག།⤵ང་ཅ་ཆ།',
  reference: '1-12',
);

Future<FakeLocalStorage> _pump(
  WidgetTester tester,
  Widget child, {
  Map<String, Object> stored = const {},
}) async {
  final storage = FakeLocalStorage()..values.addAll(stored);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      child: MaterialApp(home: Scaffold(body: ListView(children: [child]))),
    ),
  );
  await tester.pump();
  return storage;
}

SegmentItem _alone({
  bool isLive = false,
  bool followingLive = false,
  bool isSelected = false,
}) => SegmentItem(
  segment: _segment,
  depth: 0,
  language: 'bo',
  scope: _scope,
  isLive: isLive,
  followingLive: followingLive,
  isSelected: isSelected,
);

/// The colour of the card under the verse; transparent without one.
Color? _cardColor(WidgetTester tester) {
  final card = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(ReaderVerseFrame),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (card.decoration! as BoxDecoration).color;
}

void main() {
  group('verse number', () {
    testWidgets('on its own row after the text, at the right margin', (
      tester,
    ) async {
      await _pump(tester, _alone());
      final number = find.text('༡.༡༢');
      expect(number, findsOneWidget);

      final text = tester.getRect(find.byType(SegmentHtmlWidget));
      final label = tester.getRect(number);
      expect(label.top, greaterThanOrEqualTo(text.bottom));
      expect(label.right, closeTo(800 - 16, 0.5));
      // Medium, at the card's Tibetan verse number size (16 at step 3).
      final style = tester.widget<Text>(number).style!;
      expect(style.fontWeight, FontWeight.w500);
      expect(style.fontSize, 16);
    });

    testWidgets('hidden while verse numbers are turned off', (tester) async {
      await _pump(
        tester,
        _alone(),
        stored: {StorageKeys.readerVerseNumbers: false},
      );
      expect(find.text('༡.༡༢'), findsNothing);
    });

    testWidgets('with a translation, its numerals are the translation\'s', (
      tester,
    ) async {
      await _pump(
        tester,
        InterlinearSegmentItem(
          segment: _segment,
          depth: 0,
          primaryLanguage: 'en',
          scope: _scope,
          secondarySlot: const ReaderSlotConfig(
            languageCode: 'bo',
            languageLabel: 'Tibetan',
          ),
          secondaryContentBySegmentNumber: const {12: 'ཀ།'},
        ),
      );
      expect(find.text('༡.༡༢'), findsOneWidget);
    });
  });

  group('lines', () {
    List<String> drawn(WidgetTester tester) => [
      for (final html in tester.widgetList<SegmentHtmlWidget>(
        find.byType(SegmentHtmlWidget),
      ))
        html.htmlContent,
    ];

    testWidgets('pair line by line when the counts match', (tester) async {
      await _pump(
        tester,
        InterlinearSegmentItem(
          segment: _segment,
          depth: 0,
          primaryLanguage: 'bo',
          scope: _scope,
          secondarySlot: const ReaderSlotConfig(
            languageCode: 'bo',
            languageLabel: 'Tibetan',
          ),
          secondaryContentBySegmentNumber: const {12: 'ཏ།⤵ཐ།'},
        ),
      );
      expect(drawn(tester), ['ཀ་ཁ་ག།', 'ཏ།', 'ང་ཅ་ཆ།', 'ཐ།']);
    });

    testWidgets('stay two blocks when they do not', (tester) async {
      await _pump(
        tester,
        InterlinearSegmentItem(
          segment: _segment,
          depth: 0,
          primaryLanguage: 'bo',
          scope: _scope,
          secondarySlot: const ReaderSlotConfig(
            languageCode: 'bo',
            languageLabel: 'Tibetan',
          ),
          secondaryContentBySegmentNumber: const {12: 'ཏ།'},
        ),
      );
      expect(drawn(tester), ['ཀ་ཁ་ག།<br>ང་ཅ་ཆ།', 'ཏ།']);
    });
  });

  group('live', () {
    final palette = ReaderPalette.of(
      ReaderBackground.ricePaper,
      Brightness.light,
    );

    test('the live verse is at full strength, the rest muted', () {
      final live = readerVerseColors(
        palette,
        isLive: true,
        followingLive: true,
        translationUnderOriginal: true,
      );
      expect(live.original, palette.liveOriginal);
      expect(live.translation, palette.translation);

      final other = readerVerseColors(
        palette,
        isLive: false,
        followingLive: true,
        translationUnderOriginal: true,
      );
      expect(other.original, palette.pastVerse);
      expect(other.translation, palette.pastVerse);
    });

    test('outside live, or Paused, the page is the normal page', () {
      final normal = readerVerseColors(
        palette,
        isLive: false,
        followingLive: false,
        translationUnderOriginal: true,
      );
      expect(normal.original, palette.text);
      expect(normal.translation, palette.translation);

      final translationAlone = readerVerseColors(
        palette,
        isLive: false,
        followingLive: false,
        translationUnderOriginal: false,
      );
      expect(translationAlone.translation, palette.text);
    });

    testWidgets('the live verse sits on a rounded card', (tester) async {
      await _pump(tester, _alone(isLive: true, followingLive: true));
      final card = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(ReaderVerseFrame),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = card.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));
      expect(decoration.color, isNot(Colors.transparent));
    });

    testWidgets('the verse whose sheet is open sits on the card, not underlined',
        (tester) async {
      await _pump(tester, _alone());
      expect(_cardColor(tester), Colors.transparent);

      await _pump(tester, _alone(isSelected: true));
      expect(_cardColor(tester), isNot(Colors.transparent));
      expect(
        tester
            .widgetList<SegmentHtmlWidget>(find.byType(SegmentHtmlWidget))
            .every((line) => !line.isSelected),
        isTrue,
      );
    });

    testWidgets('a verse does not move when it becomes live', (tester) async {
      await _pump(tester, _alone());
      final before = tester.getTopLeft(find.byType(SegmentHtmlWidget));
      await _pump(tester, _alone(isLive: true, followingLive: true));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(SegmentHtmlWidget)), before);
    });
  });
}
