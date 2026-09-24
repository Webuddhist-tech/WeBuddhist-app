import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_script_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';

/// Languages, scripts and versions behind the reader's Languages sheet.
abstract class ReaderSettingsRemoteDatasource {
  Future<ReaderLanguagesResponse> fetchLanguages({required String textId});

  Future<ReaderScriptsResponse> fetchScripts({
    required String textId,
    required String language,
  });

  Future<ReaderVersionsResponse> fetchVersions({
    required String textId,
    required String language,
  });

  Future<ReaderVersionDetail> fetchVersionInfo({required String versionId});
}
