import 'package:flutter/foundation.dart' show listEquals;

/// A section of the page's table of contents: the innermost titled heading
/// over a run of verses, or a text's title when it has none.
class ReaderPageSection {
  final int source;
  final String id;
  final String title;
  final String language;

  /// The entry to bring to the top: the heading, or the first verse when
  /// the heading was drawn for an earlier source. -1 while the verse it
  /// opens at is not on the page.
  final int entryIndex;

  /// The verse it opens at, to load it when it is not on the page; null for
  /// a section known only from the loaded pages.
  final String? segmentId;

  const ReaderPageSection({
    required this.source,
    required this.id,
    required this.title,
    required this.language,
    required this.entryIndex,
    this.segmentId,
  });

  bool get isOnPage => entryIndex >= 0;

  String get key => '$source:$id';

  @override
  bool operator ==(Object other) =>
      other is ReaderPageSection &&
      other.source == source &&
      other.id == id &&
      other.title == title &&
      other.language == language &&
      other.entryIndex == entryIndex &&
      other.segmentId == segmentId;

  @override
  int get hashCode =>
      Object.hash(source, id, title, language, entryIndex, segmentId);
}

/// A text of the page as the navigator lists it, with its sections nested.
class ReaderPageText {
  final int source;
  final String title;
  final String language;
  final int entryIndex;

  /// The section the text is named after, left out of [sections].
  final String titleSectionId;

  /// The verse the text opens at while it is not on the page (the page was
  /// loaded from further in), to load it; null when [entryIndex] is it.
  final String? startSegmentId;
  final List<ReaderPageSection> sections = [];

  ReaderPageText({
    required this.source,
    required this.title,
    required this.language,
    required this.entryIndex,
    required this.titleSectionId,
    this.startSegmentId,
  });

  /// The text as a place to go to: its start.
  ReaderPageSection get start => ReaderPageSection(
    source: source,
    id: titleSectionId,
    title: title,
    language: language,
    entryIndex: startSegmentId == null ? entryIndex : -1,
    segmentId: startSegmentId,
  );

  @override
  bool operator ==(Object other) =>
      other is ReaderPageText &&
      other.source == source &&
      other.title == title &&
      other.language == language &&
      other.entryIndex == entryIndex &&
      other.startSegmentId == startSegmentId &&
      listEquals(other.sections, sections);

  @override
  int get hashCode => Object.hash(
    source,
    title,
    language,
    entryIndex,
    startSegmentId,
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
