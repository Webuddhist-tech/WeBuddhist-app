import 'package:flutter/foundation.dart' show listEquals;

/// A section of the page's table of contents: the innermost titled heading
/// over a run of verses, or a text's title when it has none.
class ReaderPageSection {
  final int source;
  final String id;
  final String title;
  final String language;

  /// The entry to bring to the top: the heading, or the first verse when
  /// the heading was drawn for an earlier source.
  final int entryIndex;

  const ReaderPageSection({
    required this.source,
    required this.id,
    required this.title,
    required this.language,
    required this.entryIndex,
  });

  String get key => '$source:$id';

  @override
  bool operator ==(Object other) =>
      other is ReaderPageSection &&
      other.source == source &&
      other.id == id &&
      other.title == title &&
      other.language == language &&
      other.entryIndex == entryIndex;

  @override
  int get hashCode => Object.hash(source, id, title, language, entryIndex);
}

/// A text of the page as the navigator lists it, with its sections nested.
class ReaderPageText {
  final int source;
  final String title;
  final String language;
  final int entryIndex;

  /// The section the text is named after, left out of [sections].
  final String titleSectionId;
  final List<ReaderPageSection> sections = [];

  ReaderPageText({
    required this.source,
    required this.title,
    required this.language,
    required this.entryIndex,
    required this.titleSectionId,
  });

  @override
  bool operator ==(Object other) =>
      other is ReaderPageText &&
      other.source == source &&
      other.title == title &&
      other.language == language &&
      other.entryIndex == entryIndex &&
      listEquals(other.sections, sections);

  @override
  int get hashCode => Object.hash(
    source,
    title,
    language,
    entryIndex,
    Object.hashAll(sections),
  );
}

/// What the sections sheet shows.
class ReaderSectionsSnapshot {
  final String title;
  final List<ReaderPageText> texts;

  /// Texts of the page not loaded yet.
  final int pendingSources;

  const ReaderSectionsSnapshot({
    required this.title,
    required this.texts,
    required this.pendingSources,
  });

  const ReaderSectionsSnapshot.empty()
    : title = '',
      texts = const [],
      pendingSources = 0;

  @override
  bool operator ==(Object other) =>
      other is ReaderSectionsSnapshot &&
      other.title == title &&
      other.pendingSources == pendingSources &&
      listEquals(other.texts, texts);

  @override
  int get hashCode => Object.hash(title, pendingSources, Object.hashAll(texts));
}
