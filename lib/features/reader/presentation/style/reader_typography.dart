import 'package:flutter_pecha/features/reader/constants/reader_constants.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sizes, font families and line heights of the reader page.
///
/// Reader widgets take their text metrics from here rather than from the
/// font size setting, so the size rules are decided in one place.
class ReaderTypography {
  const ReaderTypography({required this.fontSize});

  /// The text size the reader is set to.
  final double fontSize;

  /// The typography for the reader's current settings.
  static ReaderTypography resolve(WidgetRef ref) =>
      ReaderTypography(fontSize: ref.watch(fontSizeProvider));

  /// A verse's original line.
  double get originalSize => fontSize;

  /// A verse's translation line.
  double get translationSize => fontSize;

  double get verseNumberSize =>
      fontSize * ReaderConstants.segmentNumberFontScale;

  /// A section heading [depth] levels down from the top.
  double headingSize(int depth) =>
      fontSize *
      switch (depth) {
        0 => 1.2,
        1 => 1.0,
        _ => 0.9,
      };

  /// A top-level heading's number.
  double get sectionNumberSize => fontSize * 0.9;

  /// A text's title on a page of several texts.
  double get textTitleSize => fontSize * 1.2;

  String? family(String language) => getFontFamily(language);

  /// Line height of verse text; null leaves the font's own.
  double? verseHeight(String language) => null;

  double? headingHeight(String language) => getLineHeight(language);

  /// The line standing in for a translation that is loading or missing.
  double get placeholderHeight => 1.4;
}
