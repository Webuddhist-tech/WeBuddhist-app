import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_providers.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/home/presentation/providers/home_poems_preview_provider.dart';
import 'package:flutter_pecha/features/poems/data/datasource/poems_remote_datasource.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/features/poems/presentation/providers/poems_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemote extends PoemsRemoteDatasource {
  _FakeRemote() : super(dio: Dio());

  Object? response;
  Exception? error;
  bool? lastNoCache;

  @override
  Future<Object> fetchPoemsJson({
    required String language,
    int skip = 0,
    int limit = 20,
    String? chapterName,
    String? authorName,
    bool noCache = false,
  }) async {
    lastNoCache = noCache;
    if (error != null) throw error!;
    return response!;
  }
}

Map<String, dynamic> _page(List<String> ids) => {
  'poems': [
    for (final id in ids) {'id': id, 'title': 'Poem $id', 'content': '...'},
  ],
  'total': ids.length,
};

List<String> _ids(AsyncValue<List<Poem>> value) =>
    value.valueOrNull?.map((p) => p.id).toList() ?? const [];

void main() {
  late FakeScreenCacheStore store;
  late _FakeRemote remote;
  final key = ScreenCacheKey.public('home_poems', language: 'en');

  setUp(() {
    store = FakeScreenCacheStore();
    remote = _FakeRemote();
  });

  ProviderContainer build() {
    final container = ProviderContainer(
      overrides: [
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        poemsRemoteDatasourceProvider.overrideWithValue(remote),
        screenCacheStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('stored preview shows first, then the refreshed one', () async {
    store.entries[key] = jsonEncode(_page(['p1']));
    remote.response = _page(['p1', 'p2']);
    final container = build();

    final seen = <List<String>>[];
    container.listen(homePoemsPreviewProvider, (_, next) {
      if (next.hasValue) seen.add(_ids(next));
    }, fireImmediately: true);
    await pumpEventQueue();

    expect(seen, [
      ['p1'],
      ['p1', 'p2'],
    ]);
    expect(remote.lastNoCache, isTrue);
  });

  test('a failure with nothing stored is an empty preview', () async {
    remote.error = const NetworkException('offline');
    final container = build();
    container.listen(homePoemsPreviewProvider, (_, __) {});
    await pumpEventQueue();
    final value = container.read(homePoemsPreviewProvider);
    expect(value.hasValue, isTrue);
    expect(_ids(value), isEmpty);
  });
}
