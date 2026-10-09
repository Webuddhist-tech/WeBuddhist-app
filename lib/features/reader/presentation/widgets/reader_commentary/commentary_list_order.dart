import 'package:flutter_pecha/features/reader/presentation/widgets/reader_commentary/commentary_language_order.dart';
import 'package:flutter_pecha/features/texts/data/models/commentary/segment_commentary.dart';

/// How the commentary sheet lists its cards.
///
/// [pinned] is the first commentary whose text id matches the plan task's
/// `commentary_text_id`, including translation editions nested under a
/// commentary. It is drawn above every language section and left out of
/// [byLanguage]. Later cards with the same id stay in their sections.
class CommentaryListOrder {
  const CommentaryListOrder({
    required this.pinned,
    required this.byLanguage,
    required this.languageCodes,
  });

  final SegmentCommentary? pinned;
  final Map<String, List<SegmentCommentary>> byLanguage;
  final List<String> languageCodes;
}

CommentaryListOrder orderCommentaries({
  required List<SegmentCommentary> commentaries,
  required String textLanguage,
  required bool pinEnglish,
  String? commentaryTextId,
}) {
  final pinned = _firstMatch(commentaries, commentaryTextId);
  final byLanguage = <String, List<SegmentCommentary>>{};
  for (final commentary in _flatten(commentaries)) {
    if (identical(commentary, pinned)) continue;
    byLanguage.putIfAbsent(commentary.language, () => []).add(commentary);
  }
  return CommentaryListOrder(
    pinned: pinned,
    byLanguage: byLanguage,
    languageCodes: orderedCommentaryLanguageCodes(
      languages: byLanguage.keys,
      textLanguage: textLanguage,
      pinEnglish: pinEnglish,
    ),
  );
}

SegmentCommentary? _firstMatch(
  Iterable<SegmentCommentary> items,
  String? commentaryTextId,
) {
  final id = commentaryTextId?.trim();
  if (id == null || id.isEmpty) return null;
  for (final commentary in items) {
    if (commentary.textId == id) return commentary;
    final nested = _firstMatch(commentary.translations, id);
    if (nested != null) return nested;
  }
  return null;
}

Iterable<SegmentCommentary> _flatten(Iterable<SegmentCommentary> items) sync* {
  for (final commentary in items) {
    yield commentary;
    yield* _flatten(commentary.translations);
  }
}
