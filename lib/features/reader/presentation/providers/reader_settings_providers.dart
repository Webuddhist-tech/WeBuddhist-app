import 'package:flutter_pecha/features/library/data/adapters/library_reader_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/library/presentation/providers/library_providers.dart';
import 'package:flutter_pecha/features/reader/data/datasource/reader_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_script_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Languages and versions come from the library API.
final readerSettingsRemoteDatasourceProvider =
    Provider<ReaderSettingsRemoteDatasource>((ref) {
  return LibraryReaderSettingsRemoteDatasource(
    library: ref.watch(libraryRepositoryProvider),
  );
});

class ReaderLanguageQuery {
  final String textId;
  final String language;
  const ReaderLanguageQuery({required this.textId, required this.language});

  @override
  bool operator ==(Object other) =>
      other is ReaderLanguageQuery &&
      other.textId == textId &&
      other.language == language;

  @override
  int get hashCode => Object.hash(textId, language);
}

final readerLanguagesProvider = FutureProvider.family
    .autoDispose<List<ReaderLanguageOption>, String>((ref, textId) async {
  final ds = ref.watch(readerSettingsRemoteDatasourceProvider);
  final res = await ds.fetchLanguages(textId: textId);
  return res.availableLanguages;
});

final readerScriptsProvider = FutureProvider.family
    .autoDispose<List<ReaderScriptOption>, ReaderLanguageQuery>(
        (ref, query) async {
  final ds = ref.watch(readerSettingsRemoteDatasourceProvider);
  final res = await ds.fetchScripts(
    textId: query.textId,
    language: query.language,
  );
  return res.availableScripts;
});

final readerVersionsProvider = FutureProvider.family
    .autoDispose<List<ReaderVersionDetail>, ReaderLanguageQuery>(
        (ref, query) async {
  final ds = ref.watch(readerSettingsRemoteDatasourceProvider);
  final res = await ds.fetchVersions(
    textId: query.textId,
    language: query.language,
  );
  return res.availableVersions;
});

final readerVersionInfoProvider = FutureProvider.family
    .autoDispose<ReaderVersionDetail, String>((ref, versionId) async {
  final ds = ref.watch(readerSettingsRemoteDatasourceProvider);
  return ds.fetchVersionInfo(versionId: versionId);
});
