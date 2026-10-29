/// A heading of a text's table of contents, placed on the reader's verses:
/// it opens at the verse numbered [number] ([segmentId], this text's own
/// id) and holds every verse up to [endNumber]. [depth] is 0 for a
/// top-level heading. [opensText] when no verse comes before it.
class TextOutlineSection {
  final String id;
  final String? parentId;
  final int depth;

  /// Titles by language code; a library edition holds only its own.
  final Map<String, String> titles;
  final String segmentId;
  final int number;
  final int endNumber;
  final bool opensText;

  const TextOutlineSection({
    required this.id,
    this.parentId,
    required this.depth,
    required this.titles,
    required this.segmentId,
    required this.number,
    required this.endNumber,
    this.opensText = false,
  });

  /// The title in [language], else null.
  String? titleIn(String language) {
    final code = language.trim().toLowerCase();
    for (final entry in titles.entries) {
      if (entry.key.trim().toLowerCase() == code && entry.value.isNotEmpty) {
        return entry.value;
      }
    }
    return null;
  }

  /// The title in [language], else in any language, else null.
  String? titleFor(String language) {
    final own = titleIn(language);
    if (own != null) return own;
    for (final value in titles.values) {
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  bool holds(int verseNumber) =>
      verseNumber >= number && verseNumber <= endNumber;
}

/// A text's whole table of contents, in reading order, before any of its
/// pages load. [language] is the text's own, the one its titles are in.
class TextOutline {
  final String language;
  final List<TextOutlineSection> sections;

  const TextOutline({required this.language, required this.sections});

  const TextOutline.empty() : language = '', sections = const [];

  bool get isEmpty => sections.isEmpty;
}
