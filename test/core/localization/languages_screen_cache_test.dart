import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/localization/data/languages_remote_datasource.dart';
import 'package:flutter_pecha/core/localization/languages_providers.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_screen_cache_store.dart';

class _FakeStorage implements LocalStorageService {
  final Map<String, Object?> _store = {};

  @override
  Future<T?> get<T>(String key) async => _store[key] as T?;
  @override
  Future<bool> set<T>(String key, T value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _store.clear();
    return true;
  }

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);
  @override
  Future<void> setUserData(Map<String, dynamic> userData) async {}
  @override
  Future<Map<String, dynamic>?> getUserData() async => null;
  @override
  Future<void> clearUserData() async {}
}

class _FakeDatasource extends LanguagesRemoteDatasource {
  _FakeDatasource() : super(dio: Dio());

  List<AppLanguage> languages = const [];
  Exception? error;

  @override
  Future<List<AppLanguage>> fetchLanguages({bool recitationOnly = false}) async {
    if (error != null) throw error!;
    return languages;
  }
}

AppLanguage _lang(String code) =>
    AppLanguage(code: code, name: code, nativeName: code);

List<String> _codes(AsyncValue<List<AppLanguage>> v) =>
    v.valueOrNull?.map((l) => l.code).toList() ?? const [];

void main() {
  late FakeScreenCacheStore store;
  late _FakeDatasource datasource;
  final key = ScreenCacheKey.public('languages', language: 'all');

  setUp(() {
    store = FakeScreenCacheStore();
    datasource = _FakeDatasource();
  });

  ProviderContainer build() {
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(_FakeStorage()),
        languagesRemoteDatasourceProvider.overrideWithValue(datasource),
        screenCacheStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('stored languages show first, then the server list', () async {
    store.entries[key] = jsonEncode([_lang('en').toJson()]);
    datasource.languages = [_lang('en'), _lang('bo')];
    final container = build();

    final seen = <List<String>>[];
    container.listen(availableContentLanguagesProvider, (_, next) {
      if (next.hasValue) seen.add(_codes(next));
    }, fireImmediately: true);
    await pumpEventQueue();

    expect(seen, [
      ['en'],
      ['en', 'bo'],
    ]);
    expect(store.entries[key], jsonEncode([_lang('en').toJson(), _lang('bo').toJson()]));
  });

  test('stored languages are the state on the very first read', () async {
    store.entries[key] = jsonEncode([_lang('en').toJson()]);
    datasource.languages = [_lang('en')];
    final container = build();
    container.listen(availableContentLanguagesProvider, (_, __) {});

    final first = container.read(availableContentLanguagesProvider);
    expect(first.isLoading, isFalse);
    expect(_codes(first), ['en']);
  });

  test('offline with a stored list keeps it', () async {
    store.entries[key] = jsonEncode([_lang('en').toJson(), _lang('zh').toJson()]);
    datasource.error = const NetworkException('offline');
    final container = build();

    container.listen(availableContentLanguagesProvider, (_, __) {});
    await pumpEventQueue();
    expect(_codes(container.read(availableContentLanguagesProvider)), ['en', 'zh']);
  });

  test('offline with nothing stored falls back to the bundled list', () async {
    datasource.error = const NetworkException('offline');
    final container = build();

    container.listen(availableContentLanguagesProvider, (_, __) {});
    await pumpEventQueue();
    expect(
      container.read(availableContentLanguagesProvider).valueOrNull,
      AppLanguage.bundledFallback,
    );
  });
}
