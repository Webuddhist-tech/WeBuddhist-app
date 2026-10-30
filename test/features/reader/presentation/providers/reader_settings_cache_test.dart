import 'dart:convert';

import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/reader/data/datasource/reader_settings_remote_datasource.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_script_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_screen_cache_store.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';

class _FakeSettings implements ReaderSettingsRemoteDatasource {
  ReaderVersionDetail version = const ReaderVersionDetail(
    id: 'v1',
    title: 'Fresh',
    language: 'en',
  );
  Exception? error;
  int calls = 0;

  @override
  Future<ReaderVersionDetail> fetchVersionInfo({
    required String versionId,
  }) async {
    calls++;
    if (error != null) throw error!;
    return version;
  }

  @override
  Future<ReaderLanguagesResponse> fetchLanguages({required String textId}) =>
      throw UnimplementedError();

  @override
  Future<ReaderScriptsResponse> fetchScripts({
    required String textId,
    required String language,
  }) => throw UnimplementedError();

  @override
  Future<ReaderVersionsResponse> fetchVersions({
    required String textId,
    required String language,
  }) => throw UnimplementedError();
}

void main() {
  late FakeScreenCacheStore store;
  late _FakeSettings settings;
  final key = ScreenCacheKey.public(
    'reader_version_info',
    language: 'all',
    params: ['v1'],
  );

  setUp(() {
    store = FakeScreenCacheStore();
    settings = _FakeSettings();
  });

  ProviderContainer build() {
    final container = ProviderContainer(
      overrides: [
        screenCacheStoreProvider.overrideWithValue(store),
        readerSettingsRemoteDatasourceProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('stored version shows first, then the refreshed one', () async {
    store.entries[key] = jsonEncode(
      const ReaderVersionDetail(id: 'v1', title: 'Stored', language: 'en')
          .toJson(),
    );
    final container = build();
    final titles = <String>[];
    container.listen(readerVersionInfoProvider('v1'), (_, next) {
      final title = next.valueOrNull?.title;
      if (title != null) titles.add(title);
    }, fireImmediately: true);
    await pumpEventQueue();

    expect(titles, ['Stored', 'Fresh']);
    expect(settings.calls, 1);
  });

  test('the stored version is the state on the very first read', () async {
    store.entries[key] = jsonEncode(
      const ReaderVersionDetail(id: 'v1', title: 'Stored', language: 'en')
          .toJson(),
    );
    final container = build();
    container.listen(readerVersionInfoProvider('v1'), (_, __) {});
    final first = container.read(readerVersionInfoProvider('v1'));
    expect(first.isLoading, isFalse);
    expect(first.requireValue.title, 'Stored');
  });

  test('nothing stored and no network is an error', () async {
    settings.error = const NetworkException('offline');
    final container = build();
    container.listen(readerVersionInfoProvider('v1'), (_, __) {});
    await pumpEventQueue();
    expect(container.read(readerVersionInfoProvider('v1')).hasError, isTrue);
  });
}
