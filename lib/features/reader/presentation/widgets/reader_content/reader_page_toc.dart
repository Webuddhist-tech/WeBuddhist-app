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

  /// The text's start is not on the page and no verse is known to load it
  /// by (no heading opens the text): its first page is loaded instead.
  final bool startsBeforePage;
  final List<ReaderPageSection> sections = [];

  ReaderPageText({
    required this.source,
    required this.title,
    required this.language,
    required this.entryIndex,
    required this.titleSectionId,
    this.startSegmentId,
    this.startsBeforePage = false,
  });

  /// The text as a place to go to: its start.
  ReaderPageSection get start => ReaderPageSection(
    source: source,
    id: titleSectionId,
    title: title,
    language: language,
    entryIndex: startSegmentId == null && !startsBeforePage ? entryIndex : -1,
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
      other.startsBeforePage == startsBeforePage &&
      listEquals(other.sections, sections);

  @override
  int get hashCode => Object.hash(
    source,
    title,
    language,
    entryIndex,
    startSegmentId,
    startsBeforePage,
    Object.hashAll(sections),
  );
}

/// A row of the sections sheet: a section the pill counts, the language its
/// number is written in, the group heading over it, if any ("AFTER THE
/// PUJA"), and on a page of several texts the title of the text it is in,
/// when no row of its own names that text. [isText] marks a row that is a
/// text itself on such a page.
class ReaderSheetSection {
  final ReaderPageSection section;
  final String numeralLanguage;
  final String? group;
  final String? groupLanguage;
  final String? text;
  final String? textLanguage;
  final bool isText;

  const ReaderSheetSection({
    required this.section,
    required this.numeralLanguage,
    this.group,
    this.groupLanguage,
    this.text,
    this.textLanguage,
    this.isText = false,
  });

  @override
  bool operator ==(Object other) =>
      other is ReaderSheetSection &&
      other.section == section &&
      other.numeralLanguage == numeralLanguage &&
      other.group == group &&
      other.groupLanguage == groupLanguage &&
      other.text == text &&
      other.textLanguage == textLanguage &&
      other.isText == isText;

  @override
  int get hashCode => Object.hash(
    section,
    numeralLanguage,
    group,
    groupLanguage,
    text,
    textLanguage,
    isText,
  );
}

/// What the sections sheet shows: the sections the pill counts, in order.
class ReaderSectionsSnapshot {
  final List<ReaderSheetSection> sections;

  /// Texts of the page not loaded yet; they count towards the total.
  final int pendingSources;

  /// More than one text on the page: the sheet rules them apart.
  final bool severalTexts;

  /// The section holding the verse the puja leader is on, while the reader
  /// follows a live recitation.
  final String? liveKey;

  const ReaderSectionsSnapshot({
    required this.sections,
    required this.pendingSources,
    this.severalTexts = false,
    this.liveKey,
  });

  const ReaderSectionsSnapshot.empty()
    : sections = const [],
      pendingSources = 0,
      severalTexts = false,
      liveKey = null;

  @override
  bool operator ==(Object other) =>
      other is ReaderSectionsSnapshot &&
      other.pendingSources == pendingSources &&
      other.severalTexts == severalTexts &&
      other.liveKey == liveKey &&
      listEquals(other.sections, sections);

  @override
  int get hashCode =>
      Object.hash(
        pendingSources,
        severalTexts,
        liveKey,
        Object.hashAll(sections),
      );
}
