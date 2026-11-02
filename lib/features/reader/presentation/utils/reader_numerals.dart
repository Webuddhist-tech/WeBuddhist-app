import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_script.dart';

/// The script a page's numbers are written in: the translation's, the
/// reader's stronger language, when one is shown; otherwise the original's.
/// Covers verse numbers and section counts.
ReaderScript readerNumeralScript({
  required String originalLanguage,
  String? translationLanguage,
}) => ReaderScript.ofLanguage(translationLanguage ?? originalLanguage);

/// [text]'s digits in [script]: Tibetan digits for Tibetan, the others
/// Western.
String readerNumerals(Object text, ReaderScript script) =>
    script == ReaderScript.tibetan ? toTibetanDigits(text) : '$text';

/// Fonts to fall back on for numbers in [script] set in an interface font,
/// which has no Tibetan digits.
List<String>? readerNumeralFallback(ReaderScript script) =>
    script == ReaderScript.tibetan ? const [AppConfig.tibetanSystemFont] : null;

/// A verse's label as the page shows it: the edition's `1-12` reads `1.12`.
String readerVerseLabel(String label, ReaderScript script) =>
    readerNumerals(label.replaceAll('-', '.'), script);
