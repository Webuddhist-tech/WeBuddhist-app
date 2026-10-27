import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/connect/data/datasource/connect_remote_datasource.dart';
import 'package:flutter_pecha/features/connect/data/repositories/connect_repository_impl.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemote extends ConnectRemoteDatasource {
  _FakeRemote() : super(dio: Dio());

  Map<String, dynamic>? response;
  Exception? error;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> fetchDiscoverGroupsJson({
    required String language,
    int skip = 0,
    int limit = 20,
    String? search,
  }) async {
    calls++;
    if (error != null) throw error!;
    return response!;
  }
}

Map<String, dynamic> _page(List<String> ids) => {
  'groups': [
    for (final id in ids) {'id': id, 'slug': id, 'group_type': 'COMMUNITY'},
  ],
  'skip': 0,
  'limit': 20,
  'total': ids.length,
};

void main() {
  late FakeScreenCacheStore store;
  late _FakeRemote remote;
  late ProviderContainer container;
  final key = ScreenCacheKey.user(
    'discover_groups',
    userId: 'user-1',
    language: 'en',
  );

  setUp(() {
    store = FakeScreenCacheStore();
    remote = _FakeRemote();
    container = ProviderContainer(
      overrides: [
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        connectRepositoryProvider.overrideWithValue(
          ConnectRepositoryImpl(remote: remote, store: store),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  List<String> ids(DiscoverGroupsState state) =>
      state.groups.map((g) => g.id).toList();

  test('stored page shows at once, then the server page replaces it', () async {
    store.entries[key] = jsonEncode(_page(['g1']));
    remote.response = _page(['g1', 'g2']);
    final seen = <List<String>>[];
    container.listen(discoverGroupsProvider, (_, next) {
      if (next.hasLoaded && !next.isLoading) seen.add(ids(next));
    });

    container.read(discoverGroupsProvider.notifier).ensureLoaded();
    await pumpEventQueue();

    expect(seen, [
      ['g1'],
      ['g1', 'g2'],
    ]);
    expect(store.entries[key], jsonEncode(_page(['g1', 'g2'])));
  });

  test('a failed refresh keeps the stored page without an error', () async {
    store.entries[key] = jsonEncode(_page(['g1']));
    remote.error = const NetworkException('offline');
    container.listen(discoverGroupsProvider, (_, __) {});
    container.read(discoverGroupsProvider.notifier).ensureLoaded();
    await pumpEventQueue();

    final state = container.read(discoverGroupsProvider);
    expect(ids(state), ['g1']);
    expect(state.error, isNull);
    expect(state.isLoading, isFalse);
  });

  test('nothing stored and no network is an error', () async {
    remote.error = const NetworkException('offline');
    container.listen(discoverGroupsProvider, (_, __) {});
    container.read(discoverGroupsProvider.notifier).ensureLoaded();
    await pumpEventQueue();

    final state = container.read(discoverGroupsProvider);
    expect(state.groups, isEmpty);
    expect(state.error, isNotNull);
    expect(state.hasLoaded, isTrue);
  });
}
