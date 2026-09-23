import 'package:flutter_pecha/features/library/data/models/library_text.dart';
import 'package:flutter_pecha/features/library/data/repositories/library_repository.dart';
import 'package:flutter_pecha/features/reader/data/datasource/reader_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_script_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';

/// Reader languages and versions from the library: a text's versions are the
/// root text and its translations, and a version id is a library text id.
class LibraryReaderSettingsRemoteDatasource
    extends ReaderSettingsRemoteDatasource {
  LibraryReaderSettingsRemoteDatasource({
    required super.dio,
    required LibraryRepository library,
  }) : _library = library;

  final LibraryRepository _library;

  @override
  Future<ReaderLanguagesResponse> fetchLanguages({
    required String textId,
  }) async {
    final text = await _library.getText(textId);
    final family = await _library.getTextFamily(textId);
    Map<String, String> names;
    try {
      names = await _library.getLanguageNames();
    } catch (_) {
      names = const {};
    }

    final counts = <String, int>{};
    for (final member in family) {
      counts[member.language] = (counts[member.language] ?? 0) + 1;
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

  /// The requested text comes first so it stays the default for its language.
  @override
  Future<ReaderVersionsResponse> fetchVersions({
    required String textId,
    required String language,
  }) async {
    final family = await _library.getTextFamily(textId);
    final members =
        family.where((t) => t.language == language).toList()..sort((a, b) {
          if (a.id == textId) return -1;
          if (b.id == textId) return 1;
          return 0;
        });
    return ReaderVersionsResponse(
      textId: textId,
      language: language,
      availableVersions: [for (final t in members) _version(t)],
    );
  }

  @override
  Future<ReaderVersionDetail> fetchVersionInfo({
    required String versionId,
  }) async {
    final text = await _library.getText(versionId);
    final editionId = text.primaryEditionId;
    final edition =
        editionId == null ? null : await _library.getEdition(editionId);
    return _version(text, sourceLink: edition?.source);
  }

  static ReaderVersionDetail _version(LibraryText text, {String? sourceLink}) {
    return ReaderVersionDetail(
      id: text.id,
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
