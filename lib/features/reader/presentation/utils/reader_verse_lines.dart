import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// A verse's lines as the page lays them out.
///
/// [paired]: each original line is followed by its translation line.
/// Otherwise the original is one block and the translation another, each
/// keeping its own line breaks.
class ReaderVerseLines {
  const ReaderVerseLines({
    required this.original,
    required this.translation,
    required this.paired,
  });

  /// The original's lines when [paired], else the whole original as one
  /// entry; empty when the original is not shown.
  final List<String> original;

  /// The translation's, the same way.
  final List<String> translation;
  final bool paired;
}

final _lineBreak = RegExp(r'<br\s*/?>', caseSensitive: false);
final _tags = RegExp(r'<[^>]*>');

/// [html] split at its soft breaks (`⤵`, or `<br>` once normalised), blank
/// lines dropped.
List<String> splitVerseLines(String? html) => [
  for (final line in normalizeSegmentHtml(html).split(_lineBreak))
    if (line.replaceAll(_tags, '').replaceAll('&nbsp;', ' ').trim().isNotEmpty)
      line.trim(),
];

/// Lays [original] and [translation] (either may be null when not shown)
/// out line by line when both have the same number of lines, more than one;
/// otherwise as two blocks. A verse reflows when its translation is turned
/// on or off.
ReaderVerseLines pairLines(String? original, String? translation) {
  final o = original == null ? const <String>[] : splitVerseLines(original);
  final t =
      translation == null ? const <String>[] : splitVerseLines(translation);
  if (o.length > 1 && o.length == t.length) {
    return ReaderVerseLines(original: o, translation: t, paired: true);
  }
  return ReaderVerseLines(
    original: [if (o.isNotEmpty) o.join('<br>')],
    translation: [if (t.isNotEmpty) t.join('<br>')],
    paired: false,
  );
}
