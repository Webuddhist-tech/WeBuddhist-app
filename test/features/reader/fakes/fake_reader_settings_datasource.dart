import 'dart:async';

import 'package:flutter_pecha/features/reader/data/datasource/reader_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_script_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';

/// Languages and versions served from memory. A language missing from
/// [versions] fails the way a network error would.
class FakeReaderSettingsDatasource implements ReaderSettingsRemoteDatasource {
  FakeReaderSettingsDatasource({
    required this.languages,
    required this.versions,
    this.versionInfo = const {},
  });

  final List<ReaderLanguageOption> languages;
  final Map<String, List<ReaderVersionDetail>> versions;
  final Map<String, ReaderVersionDetail> versionInfo;

  /// Languages whose versions were asked for, in order.
  final List<String> versionRequests = [];

  /// A language listed here answers only once its completer completes.
  final Map<String, Completer<void>> gates = {};

  @override
  Future<ReaderLanguagesResponse> fetchLanguages({
    required String textId,
  }) async => ReaderLanguagesResponse(
    textId: textId,
    title: null,
    availableLanguages: languages,
  );

  @override
  Future<ReaderVersionsResponse> fetchVersions({
    required String textId,
    required String language,
  }) async {
    versionRequests.add(language);
    await gates[language]?.future;
    final found = versions[language];
    if (found == null) throw StateError('versions for $language failed');
    return ReaderVersionsResponse(
      textId: textId,
      language: language,
      availableVersions: found,
    );
  }

  @override
  Future<ReaderScriptsResponse> fetchScripts({
    required String textId,
    required String language,
  }) => throw UnimplementedError();

  @override
  Future<ReaderVersionDetail> fetchVersionInfo({
    required String versionId,
  }) async {
    final found = versionInfo[versionId];
    if (found == null) throw StateError('version $versionId missing');
    return found;
  }
}
