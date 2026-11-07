import 'package:flutter_pecha/features/library/data/models/library_text.dart';
import 'package:flutter_pecha/features/library/data/repositories/library_repository.dart';
import 'package:flutter_pecha/features/reader/data/datasource/reader_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_script_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';

/// The share of the original's verses a translation edition must have a
/// counterpart for to be offered. A few lines (a homage the library holds in
/// many languages) would only lead to a near-empty page.
const double readerTranslationCoverage = 0.8;

/// How many translation languages are measured against the original at
/// once ([readerTranslationCoverage]).
const int readerCoverageChecksAtOnce = 3;

/// Reader languages and versions from the library. The reader's text id is an
/// edition id; versions are the editions of the root text and its translations.
/// A translation edition that covers too little of the original
/// ([readerTranslationCoverage]) is not offered as a version, and a
/// language with none that covers it is not offered as a translation.
class LibraryReaderSettingsRemoteDatasource
    implements ReaderSettingsRemoteDatasource {
  LibraryReaderSettingsRemoteDatasource({required LibraryRepository library})
    : _library = library;

  final LibraryRepository _library;

  @override
  Future<ReaderLanguagesResponse> fetchLanguages({
    required String textId,
  }) async {
    final edition = await _library.resolveEdition(textId);
    final text = await _library.getText(edition.textId);
    final family = await _library.getTextFamily(text.id);
    Map<String, String> names;
    try {
      names = await _library.getLanguageNames();
    } catch (_) {
      names = const {};
    }

    final measuredAgainst = _originalEditionId(family, edition.id);
    final counts = <String, int>{};
    final translationCounts = <String, int>{};
    for (final member in family) {
      if (member.editions.isEmpty) continue;
      counts[member.language] =
          (counts[member.language] ?? 0) + member.editions.length;
    }
    // A language counts as a translation when one of its editions covers
    // the original. The reader only asks whether a language has one, so
    // each language stops at its first, and a few are measured at a time:
    // a family can hold dozens of translations, each a download.
    final translations = <String, List<String>>{};
    for (final member in family) {
      if (_isRoot(member)) continue;
      translations
          .putIfAbsent(member.language, () => [])
          .addAll(member.editions);
    }
    await _forEachLimited(translations.entries, readerCoverageChecksAtOnce, (
      entry,
    ) async {
      for (final editionId in entry.value) {
        if (editionId == edition.id ||
            await _covers(measuredAgainst, editionId)) {
          translationCounts[entry.key] = entry.value.length;
          return;
        }
      }
    });
    final codes = counts.keys.toList()..sort();
    // The original's language leads: the text a translation was made from.
    final original = _byId(family)[text.translationOf] ?? text;
    if (codes.remove(original.language)) codes.insert(0, original.language);

    return ReaderLanguagesResponse(
      textId: textId,
      title: text.displayTitle,
      availableLanguages: [
        for (final code in codes)
          ReaderLanguageOption(
            code: code,
            label: _label(names, code),
            versionCount: counts[code]!,
            translationCount: translationCounts[code] ?? 0,
          ),
      ],
    );
  }

  // Scripts come from the client-side transliteration, not the library.
  @override
  Future<ReaderScriptsResponse> fetchScripts({
    required String textId,
    required String language,
  }) async {
    return ReaderScriptsResponse(
      textId: textId,
      language: language,
      availableScripts: const [],
    );
  }

  /// The opened edition comes first so it stays the default for its language.
  @override
  Future<ReaderVersionsResponse> fetchVersions({
    required String textId,
    required String language,
  }) async {
    final edition = await _library.resolveEdition(textId);
    final family = await _library.getTextFamily(edition.textId);
    final byId = _byId(family);
    final measuredAgainst = _originalEditionId(family, edition.id);
    final versions = <ReaderVersionDetail>[];
    for (final member in family) {
      if (member.language != language) continue;
      for (final editionId in member.editions) {
        // The edition opened is always offered; another translation only
        // when it covers the original.
        if (editionId != edition.id &&
            !_isRoot(member) &&
            !await _covers(measuredAgainst, editionId)) {
          continue;
        }
        final version = _version(
          member,
          editionId: editionId,
          parentId: byId[member.translationOf]?.primaryEditionId,
        );
        if (editionId == edition.id) {
          versions.insert(0, version);
        } else {
          versions.add(version);
        }
      }
    }
    return ReaderVersionsResponse(
      textId: textId,
      language: language,
      availableVersions: versions,
    );
  }

  @override
  Future<ReaderVersionDetail> fetchVersionInfo({
    required String versionId,
  }) async {
    final edition = await _library.resolveEdition(versionId);
    final text = await _library.getText(edition.textId);
    return _version(
      text,
      editionId: edition.id,
      parentId: await _rootEditionId(text),
      sourceLink: edition.source,
    );
  }

  static bool _isRoot(LibraryText text) =>
      !text.isTranslation && !text.isCommentary;

  /// The edition translations are measured against: the root text's, which
  /// [getTextFamily] lists first, else the one the reader opened.
  static String _originalEditionId(List<LibraryText> family, String opened) {
    for (final member in family) {
      if (_isRoot(member)) return member.primaryEditionId ?? opened;
    }
    return opened;
  }

  /// Whether translation [editionId] covers enough of [original]
  /// ([readerTranslationCoverage]). One that cannot be measured (a failed
  /// request) is offered rather than hidden.
  Future<bool> _covers(String original, String editionId) async {
    if (editionId == original) return true;
    try {
      return await _library.editionCoverage(original, editionId) >=
          readerTranslationCoverage;
    } catch (_) {
      return true;
    }
  }

  /// Runs [run] on each of [items], at most [limit] at once.
  static Future<void> _forEachLimited<T>(
    Iterable<T> items,
    int limit,
    Future<void> Function(T item) run,
  ) async {
    final queue = items.iterator;
    Future<void> worker() async {
      while (queue.moveNext()) {
        await run(queue.current);
      }
    }

    await Future.wait([for (var i = 0; i < limit; i++) worker()]);
  }

  static Map<String, LibraryText> _byId(List<LibraryText> texts) => {
    for (final t in texts) t.id: t,
  };

  /// The edition of the text [text] translates, else null. Reader ids are
  /// edition ids, so `translation_of` (a text id) is mapped across.
  Future<String?> _rootEditionId(LibraryText text) async {
    if (!text.isTranslation) return null;
    final root = await _library.getText(text.translationOf!);
    return root.primaryEditionId;
  }

  /// [parentId] is the edition of the text a translation was made from, so
  /// the reader can open it as the Translation layer of its original.
  static ReaderVersionDetail _version(
    LibraryText text, {
    required String editionId,
    String? parentId,
    String? sourceLink,
  }) {
    return ReaderVersionDetail(
      id: editionId,
      title: text.displayTitle,
      language: text.language,
      parentId: parentId,
      license: text.license,
      sourceLink: sourceLink,
      isRoot: _isRoot(text),
    );
  }

  static String _label(Map<String, String> names, String code) {
    final name = names[code];
    if (name == null || name.isEmpty) return code;
    return name[0].toUpperCase() + name.substring(1);
  }
}
