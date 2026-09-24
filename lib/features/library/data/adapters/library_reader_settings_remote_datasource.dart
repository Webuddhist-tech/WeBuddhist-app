import 'package:flutter_pecha/features/library/data/models/library_text.dart';
import 'package:flutter_pecha/features/library/data/repositories/library_repository.dart';
import 'package:flutter_pecha/features/reader/data/datasource/reader_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_script_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';

/// Reader languages and versions from the library. The reader's text id is an
/// edition id; versions are the editions of the root text and its translations.
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

    final counts = <String, int>{};
    for (final member in family) {
      if (member.editions.isEmpty) continue;
      counts[member.language] =
          (counts[member.language] ?? 0) + member.editions.length;
    }
    final codes = counts.keys.toList()..sort();
    if (codes.remove(text.language)) codes.insert(0, text.language);

    return ReaderLanguagesResponse(
      textId: textId,
      title: text.displayTitle,
      availableLanguages: [
        for (final code in codes)
          ReaderLanguageOption(
            code: code,
            label: _label(names, code),
            versionCount: counts[code]!,
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
    final versions = <ReaderVersionDetail>[];
    for (final member in family) {
      if (member.language != language) continue;
      for (final editionId in member.editions) {
        final version = _version(member, editionId: editionId);
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
    return _version(text, editionId: edition.id, sourceLink: edition.source);
  }

  static ReaderVersionDetail _version(
    LibraryText text, {
    required String editionId,
    String? sourceLink,
  }) {
    return ReaderVersionDetail(
      id: editionId,
      title: text.displayTitle,
      language: text.language,
      parentId: text.translationOf,
      license: text.license,
      sourceLink: sourceLink,
    );
  }

  static String _label(Map<String, String> names, String code) {
    final name = names[code];
    if (name == null || name.isEmpty) return code;
    return name[0].toUpperCase() + name.substring(1);
  }
}
