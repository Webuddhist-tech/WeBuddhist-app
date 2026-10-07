import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the vertical metrics of the bundled Tibetan fonts.
///
/// Flutter builds every line box from the font's ascender/descender. The
/// upstream Noto Serif Tibetan / BabelStone Tibetan files declare values far
/// larger than the glyphs they draw, so with the app's `height: 1.55` the box
/// no longer encloses the vowel signs (clipped on truncated paragraphs) and
/// its centre sits well below the ink (labels ride high in buttons). The
/// shipped fonts are rebuilt with fitted metrics
/// (tool/patch_tibetan_font_metrics.py); these tests fail if someone swaps an
/// upstream file back in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final ui = FontLoader(AppConfig.tibetanSystemFont)
      ..addFont(rootBundle.load('assets/fonts/NotoSerifTibetanWB-Regular.ttf'));
    final content = FontLoader(AppConfig.tibetanContentFont)
      ..addFont(rootBundle.load('assets/fonts/WBTibetanContent.ttf'));
    await ui.load();
    await content.load();
  });

  LineMetrics firstLine(String fontFamily, double fontSize, double height) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'དོ་དམ་པ།',
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          height: height,
          leadingDistribution: AppFontConfig.tibetanLeadingDistribution,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final metrics = painter.computeLineMetrics();
    painter.dispose();
    return metrics.first;
  }

  group('NotoSerifTibetanWB (system UI font)', () {
    const fontSize = 13.0;
    LineMetrics line() => firstLine(
      AppConfig.tibetanSystemFont,
      fontSize,
      AppFontConfig.tibetanUiLineHeight,
    );

    test('line box encloses vowel signs at the UI line height', () {
      final metrics = line();
      // Vowel signs (ི ེ ོ) top out at 1.078 em in this font; the upstream
      // metrics give an ascent of only 0.834 em here.
      expect(metrics.ascent, greaterThanOrEqualTo(1.08 * fontSize));
      // A single subjoined stack (ཀྱ, དྲ ...) reaches 0.47 em below baseline.
      expect(metrics.descent, greaterThanOrEqualTo(0.45 * fontSize));
    });

    test('line box is centred on the ink, not on the baseline', () {
      final metrics = line();
      // Ink of ordinary Tibetan text is centred ~0.30 em above the baseline;
      // the upstream metrics put the box centre at ~0.06 em.
      final boxCentre = (metrics.ascent - metrics.descent) / 2 / fontSize;
      expect(boxCentre, closeTo(0.30, 0.06));
    });
  });

  group('WBTibetanContent (content font)', () {
    const fontSize = 20.0;
    LineMetrics line() => firstLine(
      AppConfig.tibetanContentFont,
      fontSize,
      AppFontConfig.tibetanContentLineHeight,
    );

    test('line box encloses vowel signs at the content line height', () {
      final metrics = line();
      // Vowel signs top out at 0.84 em (0.93 em with a superscript); the
      // upstream metrics give an ascent of only 0.38 em here.
      expect(metrics.ascent, greaterThanOrEqualTo(0.93 * fontSize));
      expect(metrics.descent, greaterThanOrEqualTo(0.55 * fontSize));
    });

    test('line box is centred on the ink', () {
      final metrics = line();
      final boxCentre = (metrics.ascent - metrics.descent) / 2 / fontSize;
      expect(boxCentre, closeTo(0.22, 0.06));
    });
  });
}
