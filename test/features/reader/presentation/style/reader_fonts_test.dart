import 'package:flutter/painting.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_fonts_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_typography.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_test/flutter_test.dart';

const _original = ReaderFontLine.original;
const _translation = ReaderFontLine.translation;

ReaderTypography _with(ReaderFontChoices fonts) =>
    ReaderTypography(fonts: fonts);

/// A test that asks google_fonts for a family. On fake time its download,
/// stubbed out in tests, never comes back to fail a later test.
void _familyTest(String description, void Function() body) =>
    testWidgets(description, (_) async => body());

void main() {
  group('the fonts offered', () {
    test('each script lists its fonts, today\'s first', () {
      List<String> ids(ReaderScript script) => [
        for (final font in ReaderFonts.forScript(script)) font.id,
      ];
      expect(ids(ReaderScript.latin), ['source-serif-4', 'literata', 'inter']);
      expect(ids(ReaderScript.cyrillic), ids(ReaderScript.latin));
      expect(ids(ReaderScript.tibetan), [
        'babelstone',
        'noto-serif-tibetan',
        'jomolhari',
      ]);
      expect(ids(ReaderScript.chinese), [
        'noto-serif-tc',
        'lxgw-wenkai-tc',
        'noto-sans-tc',
      ]);
      expect(ids(ReaderScript.devanagari), ['noto-serif-devanagari']);
    });

    test('Tibetan fonts are bundled, the others downloaded', () {
      for (final font in ReaderFonts.forScript(ReaderScript.tibetan)) {
        expect(font.isDownloaded, isFalse, reason: font.id);
      }
      for (final script in [
        ReaderScript.latin,
        ReaderScript.chinese,
        ReaderScript.devanagari,
      ]) {
        for (final font in ReaderFonts.forScript(script)) {
          expect(font.isDownloaded, isTrue, reason: font.id);
        }
      }
    });

    _familyTest('with nothing picked, lines keep today\'s fonts', () {
      const type = ReaderTypography();
      for (final language in ['en', 'bo', 'zh', 'mn']) {
        expect(
          type.family(language),
          getFontFamily(language),
          reason: language,
        );
        expect(
          type.family(language, role: ReaderTextRole.translationUnder),
          getFontFamily(language),
          reason: '$language translation',
        );
      }
      expect(type.family('bo'), 'WBTibetanContent');
    });

    _familyTest('Devanagari lines are in Noto Serif Devanagari', () {
      expect(
        const ReaderTypography().family('hi'),
        ReaderFonts.notoSerifDevanagari.family(),
      );
    });

    _familyTest('the line\'s script picks the list, not only its language', () {
      // Sanskrit typed in IAST stays in a Latin font.
      expect(
        const ReaderTypography().family('sa', script: ReaderScript.latin),
        ReaderFonts.sourceSerif4.family(),
      );
    });
  });

  group('picks', () {
    final jomolhari = const ReaderFontChoices().pick(
      _original,
      ReaderScript.tibetan,
      ReaderFonts.jomolhari,
    );

    _familyTest('the original and the translation keep their own pick', () {
      final both = jomolhari.pick(
        _translation,
        ReaderScript.latin,
        ReaderFonts.literata,
      );
      expect(
        both.fontFor(_original, ReaderScript.tibetan),
        ReaderFonts.jomolhari,
      );
      expect(
        both.fontFor(_translation, ReaderScript.tibetan),
        ReaderFonts.babelStone,
      );
      expect(
        both.fontFor(_translation, ReaderScript.latin),
        ReaderFonts.literata,
      );
      expect(
        both.fontFor(_original, ReaderScript.latin),
        ReaderFonts.sourceSerif4,
      );

      final type = _with(both);
      expect(type.family('bo'), 'WBTibetanUchen');
      expect(
        type.family('en', role: ReaderTextRole.translationUnder),
        ReaderFonts.literata.family(),
      );
      expect(type.family('en'), ReaderFonts.sourceSerif4.family());
    });

    test('picking the default clears the pick', () {
      final cleared = jomolhari.pick(
        _original,
        ReaderScript.tibetan,
        ReaderFonts.babelStone,
      );
      expect(cleared, const ReaderFontChoices());
      expect(cleared.toJson(), '{}');
    });

    test('a font changes no size or line height', () {
      final plain = const ReaderTypography();
      final picked = _with(jomolhari);
      for (final role in ReaderTextRole.values) {
        for (final script in ReaderScript.values) {
          final a = plain.line(role, script);
          final b = picked.line(role, script);
          expect(
            (b.fontSize, b.lineHeight),
            (a.fontSize, a.lineHeight),
            reason: '$role $script',
          );
        }
      }
    });
  });

  group('saved picks', () {
    test('round-trip, defaults left out', () {
      final choices = const ReaderFontChoices()
          .pick(_original, ReaderScript.tibetan, ReaderFonts.jomolhari)
          .pick(_translation, ReaderScript.latin, ReaderFonts.inter)
          .pick(_translation, ReaderScript.chinese, ReaderFonts.notoSerifTc);
      final json = choices.toJson();
      expect(
        json,
        '{"original":{"tibetan":"jomolhari"},"translation":{"latin":"inter"}}',
      );
      expect(ReaderFontChoices.fromJson(json), choices);
    });

    test('anything unknown reads as the default', () {
      for (final json in [
        null,
        '',
        'not json',
        '[]',
        '{"original":"jomolhari"}',
        '{"original":{"tibetan":7}}',
        // A font dropped from the list, and one from another script.
        '{"original":{"tibetan":"monlam","latin":"jomolhari"}}',
      ]) {
        expect(
          ReaderFontChoices.fromJson(json),
          const ReaderFontChoices(),
          reason: json,
        );
      }
    });
  });

  group('headings', () {
    _familyTest('Latin and Cyrillic headings are in Literata SemiBold', () {
      final literata = ReaderFonts.literata.family(weight: FontWeight.w600);
      const type = ReaderTypography();
      expect(type.headingFamily('en', ReaderScript.latin), literata);
      expect(type.headingFamily('mn', ReaderScript.cyrillic), literata);
      expect(literata, isNot(ReaderFonts.literata.family()));
      expect(type.heading(0, ReaderScript.latin).fontWeight, FontWeight.w600);
    });

    _familyTest('other headings follow the original\'s pick', () {
      final type = _with(
        const ReaderFontChoices().pick(
          _original,
          ReaderScript.tibetan,
          ReaderFonts.notoSerifTibetan,
        ),
      );
      expect(
        type.headingFamily('bo', ReaderScript.tibetan),
        'NotoSerifTibetanWB',
      );
      expect(
        const ReaderTypography().headingFamily('zh', ReaderScript.chinese),
        getFontFamily('zh'),
      );
    });
  });

  group('fonts to load before the page shows', () {
    test('only downloaded fonts someone picked', () {
      const none = ReaderFontChoices();
      expect(
        none.pickedDownloads(
          original: ReaderScript.chinese,
          translation: ReaderScript.latin,
        ),
        isEmpty,
      );

      final picked = none
          .pick(_original, ReaderScript.tibetan, ReaderFonts.jomolhari)
          .pick(_translation, ReaderScript.latin, ReaderFonts.literata)
          .pick(_original, ReaderScript.chinese, ReaderFonts.lxgwWenKaiTc);
      // Jomolhari is bundled; the Chinese pick is not on this page.
      expect(
        picked.pickedDownloads(
          original: ReaderScript.tibetan,
          translation: ReaderScript.latin,
        ),
        [ReaderFonts.literata],
      );
      expect(
        picked.pickedDownloads(translation: ReaderScript.tibetan),
        isEmpty,
      );
    });

    test('the load key names each font once, sorted', () {
      expect(
        readerFontPreloadKey([
          ReaderFonts.literata,
          ReaderFonts.inter,
          ReaderFonts.literata,
        ]),
        'inter,literata',
      );
    });
  });
}
