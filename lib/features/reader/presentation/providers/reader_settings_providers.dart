import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_notifier.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/features/library/data/adapters/library_reader_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/library/presentation/providers/library_providers.dart';
import 'package:flutter_pecha/features/reader/data/datasource/reader_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_script_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

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

/// Stored catalogue data is the first state, refreshed in the background; a
/// failure with nothing stored is the error callers already handle.
ScreenCacheSource<T> _stored<T extends Object>(
  Ref ref, {
  required String screen,
  required List<String> params,
  required Future<Object> Function() fetchJson,
  required T Function(Object json) fromJson,
}) {
  return ScreenCacheSource<T>(
    store: ref.watch(screenCacheStoreProvider),
    key: ScreenCacheKey.public(screen, language: 'all', params: params),
    fetchJson: fetchJson,
    fromJson: fromJson,
    failureMessage: 'Failed to load reader settings',
  );
}

T _orThrow<T extends Object>(Either<Failure, T> result) =>
    result.fold((failure) => throw Exception(failure.message), (v) => v);

final readerLanguagesProvider = AsyncNotifierProvider.autoDispose.family<
  AutoDisposeScreenCacheFamilyNotifier<
    List<ReaderLanguageOption>,
    List<ReaderLanguageOption>,
    String
  >,
  List<ReaderLanguageOption>,
  String
>(() {
  return AutoDisposeScreenCacheFamilyNotifier((ref, textId, bind) {
    final ds = ref.watch(readerSettingsRemoteDatasourceProvider);
    return bind.source(
      _stored(
        ref,
        screen: 'reader_languages',
        params: [textId],
        fetchJson: () async {
          final res = await ds.fetchLanguages(textId: textId);
          return res.availableLanguages.map((o) => o.toJson()).toList();
        },
        fromJson:
            (json) =>
                (json as List)
                    .map(
                      (e) => ReaderLanguageOption.fromJson(
                        e as Map<String, dynamic>,
                      ),
                    )
                    .toList(),
      ),
      select: _orThrow,
    );
  });
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

final readerVersionsProvider = AsyncNotifierProvider.autoDispose.family<
  AutoDisposeScreenCacheFamilyNotifier<
    List<ReaderVersionDetail>,
    List<ReaderVersionDetail>,
    ReaderLanguageQuery
  >,
  List<ReaderVersionDetail>,
  ReaderLanguageQuery
>(() {
  return AutoDisposeScreenCacheFamilyNotifier((ref, query, bind) {
    final ds = ref.watch(readerSettingsRemoteDatasourceProvider);
    return bind.source(
      _stored(
        ref,
        screen: 'reader_versions',
        params: [query.textId, query.language],
        fetchJson: () async {
          final res = await ds.fetchVersions(
            textId: query.textId,
            language: query.language,
          );
          return res.availableVersions.map((v) => v.toJson()).toList();
        },
        fromJson:
            (json) =>
                (json as List)
                    .map(
                      (e) => ReaderVersionDetail.fromJson(
                        e as Map<String, dynamic>,
                      ),
                    )
                    .toList(),
      ),
      select: _orThrow,
    );
  });
});

final readerVersionInfoProvider = AsyncNotifierProvider.autoDispose.family<
  AutoDisposeScreenCacheFamilyNotifier<
    ReaderVersionDetail,
    ReaderVersionDetail,
    String
  >,
  ReaderVersionDetail,
  String
>(() {
  return AutoDisposeScreenCacheFamilyNotifier((ref, versionId, bind) {
    final ds = ref.watch(readerSettingsRemoteDatasourceProvider);
    return bind.source(
      _stored(
        ref,
        screen: 'reader_version_info',
        params: [versionId],
        fetchJson:
            () async => (await ds.fetchVersionInfo(versionId: versionId)).toJson(),
        fromJson:
            (json) => ReaderVersionDetail.fromJson(json as Map<String, dynamic>),
      ),
      select: _orThrow,
    );
  });
});
