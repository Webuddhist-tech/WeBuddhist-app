import 'package:flutter/painting.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_typography.dart';
import 'package:flutter_test/flutter_test.dart';

ReaderTypography _at(
  int step, {
  ReaderSpacing spacing = ReaderSpacing.normal,
}) => ReaderTypography(
  settings: ReaderTextSize(
    originalStep: step,
    translationStep: step,
    spacing: spacing,
  ),
);

/// "size/line height" as the design's tables print it.
String _pair(ReaderTextMetrics m) =>
    '${m.fontSize.toInt()}/${m.lineHeight.toInt()}';

List<String> _row(ReaderTextMetrics Function(ReaderTypography type) line) => [
  for (var step = 1; step <= 7; step++) _pair(line(_at(step))),
];

void main() {
  group('size table at step 3', () {
    // The "Type, size and spacing" card, columns Latin, Tibetan, Chinese,
    // Devanagari, Cyrillic.
    const scripts = [
      ReaderScript.latin,
      ReaderScript.tibetan,
      ReaderScript.chinese,
      ReaderScript.devanagari,
      ReaderScript.cyrillic,
    ];
    final type = _at(3);

    List<String> roleRow(ReaderTextRole role) => [
      for (final script in scripts) _pair(type.line(role, script)),
    ];

    test('original alone', () {
      expect(roleRow(ReaderTextRole.originalAlone), [
        '18/25', '27/51', '19/30', '18/29', '18/25', //
      ]);
    });

    test('original with a translation under it', () {
      expect(roleRow(ReaderTextRole.originalWithTranslation), [
        '18/25', '22/42', '18/29', '18/29', '18/25', //
      ]);
    });

    test('translation under an original', () {
      expect(roleRow(ReaderTextRole.translationUnder), [
        '16/22', '19/36', '17/27', '17/27', '16/22', //
      ]);
    });

    test('translation alone', () {
      expect(roleRow(ReaderTextRole.translationAlone), [
        '17/24', '27/51', '19/30', '18/29', '17/24', //
      ]);
    });

    test('top-level heading', () {
      expect([for (final s in scripts) _pair(type.heading(0, s))], [
        '22/30', '32/62', '23/36', '22/35', '22/30', //
      ]);
    });

    test('instruction line', () {
      expect([for (final s in scripts) _pair(type.instruction(s))], [
        '15/21', '23/44', '16/26', '15/24', '15/21', //
      ]);
    });

    test('verse number', () {
      expect([for (final s in scripts) type.verseNumberSize(s)], [
        11, 16, 11, 11, 11, //
      ]);
    });
  });

  group('worked example, Normal spacing, steps 1 to 7', () {
    test('Latin original', () {
      expect(
        _row((t) => t.line(ReaderTextRole.originalAlone, ReaderScript.latin)),
        ['14/20', '16/23', '18/25', '21/29', '23/33', '27/38', '32/44'],
      );
    });

    test('translation under it', () {
      expect(
        _row(
          (t) => t.line(ReaderTextRole.translationUnder, ReaderScript.latin),
        ),
        ['13/18', '14/20', '16/22', '18/26', '21/29', '24/34', '28/39'],
      );
    });

    test('Tibetan alone', () {
      expect(
        _row(
          (t) => t.line(ReaderTextRole.originalAlone, ReaderScript.tibetan),
        ),
        ['22/41', '24/46', '27/51', '31/59', '35/67', '41/77', '47/90'],
      );
    });

    test('Chinese alone', () {
      expect(
        _row(
          (t) => t.line(ReaderTextRole.originalAlone, ReaderScript.chinese),
        ),
        ['15/24', '17/27', '19/30', '22/35', '25/40', '29/46', '33/53'],
      );
    });

    test('Latin heading', () {
      expect(_row((t) => t.heading(0, ReaderScript.latin)), [
        '17/24', '19/27', '22/30', '25/35', '28/39', '32/45', '38/53', //
      ]);
    });

    test('Latin verse number, never below 10', () {
      expect(
        [for (var step = 1; step <= 7; step++) _at(step).verseNumberSize()],
        [10, 10, 11, 12, 14, 16, 19],
      );
    });

    test('gaps between verses and between line pairs', () {
      final gaps = [for (var step = 1; step <= 7; step++) _at(3).gaps(step)];
      expect(gaps.map((g) => g.verse), [19, 22, 24, 28, 31, 36, 42]);
      expect(gaps.map((g) => g.pair), [10, 11, 12, 14, 16, 18, 21]);
    });
  });

  group('spacing', () {
    double lineHeight(ReaderScript script, ReaderSpacing spacing) =>
        _at(3, spacing: spacing)
            .line(ReaderTextRole.originalAlone, script)
            .lineHeight;

    test('Latin 18 is 23 / 25 / 29 high', () {
      expect(
        ReaderSpacing.values.map((s) => lineHeight(ReaderScript.latin, s)),
        [23, 25, 29],
      );
    });

    test('Tibetan 27 is 41 / 51 / 59 high; Compact is a fixed 1.5', () {
      expect(
        ReaderSpacing.values.map((s) => lineHeight(ReaderScript.tibetan, s)),
        [41, 51, 59],
      );
    });

    test('gaps at the default step', () {
      ({double verse, double pair, double inPair}) gaps(ReaderSpacing s) =>
          _at(3, spacing: s).gaps(3);
      expect(gaps(ReaderSpacing.compact), (verse: 16, pair: 8, inPair: 0));
      expect(gaps(ReaderSpacing.normal), (verse: 24, pair: 12, inPair: 2));
      expect(gaps(ReaderSpacing.relaxed), (verse: 32, pair: 16, inPair: 6));
    });
  });

  group('weights and styles', () {
    final type = _at(3);

    test('a Latin original is SemiBold, other scripts regular', () {
      expect(
        type.line(ReaderTextRole.originalAlone, ReaderScript.latin).fontWeight,
        FontWeight.w600,
      );
      expect(
        type.line(ReaderTextRole.originalAlone, ReaderScript.tibetan)
            .fontWeight,
        isNull,
      );
    });

    test('a Latin or Cyrillic translation under an original is italic', () {
      for (final script in [ReaderScript.latin, ReaderScript.cyrillic]) {
        expect(
          type.line(ReaderTextRole.translationUnder, script).fontStyle,
          FontStyle.italic,
        );
        expect(
          type.line(ReaderTextRole.translationAlone, script).fontStyle,
          isNull,
        );
      }
      expect(
        type.line(ReaderTextRole.translationUnder, ReaderScript.chinese)
            .fontStyle,
        isNull,
      );
    });

    test('headings are SemiBold', () {
      expect(type.heading(1, ReaderScript.tibetan).fontWeight, FontWeight.w600);
    });
  });

  group('headings by depth', () {
    // ×1.2 / 1.0 / 0.9 of the script's "alone" size.
    final type = _at(3);

    test('Latin 22 / 18 / 16, Tibetan 32 / 27 / 24', () {
      expect([for (var d = 0; d < 3; d++) type.heading(d, ReaderScript.latin)]
          .map((m) => m.fontSize), [22, 18, 16]);
      expect([for (var d = 0; d < 3; d++) type.heading(d, ReaderScript.tibetan)]
          .map((m) => m.fontSize), [32, 27, 24]);
    });

    test('deeper levels stay at 0.9', () {
      expect(type.heading(5, ReaderScript.latin).fontSize, 16);
    });
  });

  group('interface text', () {
    test('script factors: Tibetan 1.5, Chinese 1.05, the others 1', () {
      expect({for (final s in ReaderScript.values) s: s.interfaceScale}, {
        ReaderScript.latin: 1.0,
        ReaderScript.tibetan: 1.5,
        ReaderScript.chinese: 1.05,
        ReaderScript.devanagari: 1.0,
        ReaderScript.cyrillic: 1.0,
      });
    });

    test('section pill 14 (Tibetan 21, Chinese 15); bar and Live pill 13 '
        '(Tibetan 20, Chinese 14)', () {
      List<double> sizes(double size) => [
        for (final s in [
          ReaderScript.latin,
          ReaderScript.tibetan,
          ReaderScript.chinese,
        ])
          ReaderTypography.chromeSize(size, s),
      ];
      expect(sizes(ReaderTypography.sectionPillSize), [14, 21, 15]);
      expect(sizes(ReaderTypography.bottomBarSize), [13, 20, 14]);
    });
  });

  test('each line follows its own step', () {
    const type = ReaderTypography(
      settings: ReaderTextSize(originalStep: 1, translationStep: 7),
    );
    expect(
      type
          .line(ReaderTextRole.originalWithTranslation, ReaderScript.latin)
          .fontSize,
      14,
    );
    expect(
      type.line(ReaderTextRole.translationUnder, ReaderScript.latin).fontSize,
      28,
    );
  });
}
