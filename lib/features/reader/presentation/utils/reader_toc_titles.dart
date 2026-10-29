import 'package:flutter_pecha/features/reader/domain/transliteration/transliteration_service.dart';
import 'package:flutter_pecha/features/texts/data/models/text/text_outline.dart';

/// Leading head marks and shads (༄༅། །): they open a title, and say nothing
/// in another script.
final _titleMarks = RegExp(r'^[༁-༊།-༔\s]+');

/// [title] with its leading ༄༅། ། marks taken off.
String stripTitleMarks(String title) =>
    title.replaceFirst(_titleMarks, '').trim();

/// A title in [language] as the reader shows it once that language's
/// original is shown in [scriptId]: without its leading marks, through the
/// same converter as the verses, on one line. The service caches each title
/// per script. Without a script the title is unchanged.
String readerTitleInScript(
  TransliterationService service, {
  required String title,
  required String language,
  required String? scriptId,
}) {
  if (scriptId == null || !service.supports(language)) return title;
  final bare = stripTitleMarks(title);
  if (bare.isEmpty) return title;
  return service
      .convertHtml(bare, languageCode: language, toScriptId: scriptId)
      .replaceAll(RegExp(r'\s*<br>\s*'), ' ')
      .trim();
}

/// A text's title as the page shows it, and the language its font comes
/// from: the shown translation's title ([translationTitle], in
/// [translationLanguage]) when it has one, else [title] in the script its
/// original is shown in.
({String title, String language}) readerTextTitle(
  TransliterationService service, {
  required String title,
  required String language,
  required String? scriptId,
  String? translationTitle,
  String? translationLanguage,
}) {
  if (translationLanguage != null &&
      translationTitle != null &&
      translationTitle.isNotEmpty) {
    return (title: translationTitle, language: translationLanguage);
  }
  if (scriptId == null) return (title: title, language: language);
  return (
    title: readerTitleInScript(
      service,
      title: title,
      language: language,
      scriptId: scriptId,
    ),
    language: service.fontLanguageFor(language, scriptId) ?? language,
  );
}

/// The translation's title for each section of the [original], by the
/// original section's id. Library tables of contents hold titles only in
/// their own edition's language, so the translation's sections are matched
/// to the original's by the verse they open at: the [translation]'s are
/// numbered like the original's verses. Of those opening at the same verse
/// the one at the same depth wins, else the nearest in depth. A section with
/// no match is left out.
Map<String, String> matchTranslationTitles(
  TextOutline original,
  TextOutline translation,
) {
  if (original.isEmpty || translation.isEmpty) return const {};
  final byNumber = <int, List<TextOutlineSection>>{};
  for (final section in translation.sections) {
    if (section.titleFor(translation.language) == null) continue;
    byNumber.putIfAbsent(section.number, () => []).add(section);
  }
  final titles = <String, String>{};
  for (final section in original.sections) {
    final candidates = byNumber[section.number];
    if (candidates == null) continue;
    TextOutlineSection? best;
    for (final candidate in candidates) {
      if (best == null ||
          (candidate.depth - section.depth).abs() <
              (best.depth - section.depth).abs()) {
        best = candidate;
      }
    }
    titles[section.id] = best!.titleFor(translation.language)!;
  }
  return titles;
}

/// A section's title as the reader shows it, and the language it is in:
/// the translation's own title for it ([translationTitle]), else its title
/// in the translation's language, else its own in [originalLanguage] (or
/// any), else the text's title.
({String title, String language}) readerSectionTitle({
  required Map<String, String> titles,
  required String originalLanguage,
  String? translationTitle,
  String? translationLanguage,
  required String textTitle,
  required String textLanguage,
}) {
  if (translationLanguage != null) {
    if (translationTitle != null && translationTitle.isNotEmpty) {
      return (title: translationTitle, language: translationLanguage);
    }
    final inTranslation = _titleIn(titles, translationLanguage);
    if (inTranslation != null) {
      return (title: inTranslation, language: translationLanguage);
    }
  }
  final own = _titleIn(titles, originalLanguage);
  if (own != null) return (title: own, language: originalLanguage);
  for (final entry in titles.entries) {
    if (entry.value.isNotEmpty) {
      return (title: entry.value, language: entry.key);
    }
  }
  return (title: textTitle, language: textLanguage);
}

String? _titleIn(Map<String, String> titles, String language) {
  final code = language.trim().toLowerCase();
  for (final entry in titles.entries) {
    if (entry.key.trim().toLowerCase() == code && entry.value.isNotEmpty) {
      return entry.value;
    }
  }
  return null;
}

/// The headings of [titled] that are sections of the page: those some verse
/// sits directly under. A heading whose titled subheadings hold all of its
/// verses, one after another, only groups them; it still names a text.
List<TextOutlineSection> readerPageSections(List<TextOutlineSection> titled) {
  final children = <String, List<TextOutlineSection>>{};
  for (final section in titled) {
    final parent = section.parentId;
    if (parent != null) children.putIfAbsent(parent, () => []).add(section);
  }
  bool grouping(TextOutlineSection section) {
    final nested = children[section.id];
    if (nested == null) return false;
    var next = section.number;
    for (final child in nested) {
      if (child.number != next) return false;
      next = child.endNumber + 1;
    }
    return next == section.endNumber + 1;
  }

  return [
    for (final section in titled)
      if (!grouping(section)) section,
  ];
}

/// The innermost of [sections] holding the verse numbered [verseNumber],
/// or null. [sections] are in reading order with each heading before the
/// ones nested in it, so their opening verses never go down.
TextOutlineSection? innermostSectionHolding(
  List<TextOutlineSection> sections,
  int verseNumber,
) {
  // The last section opening at or before the verse.
  var low = 0;
  var high = sections.length;
  while (low < high) {
    final middle = (low + high) >> 1;
    if (sections[middle].number <= verseNumber) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  // Back from there: a later one holding the verse is nested deeper.
  for (var i = low - 1; i >= 0; i--) {
    if (sections[i].holds(verseNumber)) return sections[i];
  }
  return null;
}
