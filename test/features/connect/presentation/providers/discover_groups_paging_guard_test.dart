import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/connect/data/datasource/connect_remote_datasource.dart';
import 'package:flutter_pecha/features/connect/data/repositories/connect_repository_impl.dart';
import 'package:flutter_pecha/features/connect/domain/entities/discover_groups_page.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Page one (raw JSON) and page two (typed) are each gated by a completer.
class _FakeRemote extends ConnectRemoteDatasource {
  _FakeRemote() : super(dio: Dio());

  Completer<Map<String, dynamic>> firstPage = Completer();
  Completer<DiscoverGroupsPage> nextPage = Completer();
  int nextPageCalls = 0;

  @override
  Future<Map<String, dynamic>> fetchDiscoverGroupsJson({
    required String language,
    int skip = 0,
    int limit = 20,
    String? search,
  }) => firstPage.future;

  @override
  Future<DiscoverGroupsPage> fetchDiscoverGroups({
    required String language,
    int skip = 0,
    int limit = 20,
    String? search,
  }) {
    nextPageCalls++;
    return nextPage.future;
  }
}

Map<String, dynamic> _json(List<String> ids, {required int total}) => {
  'groups': [
    for (final id in ids) {'id': id, 'slug': id, 'group_type': 'COMMUNITY'},
  ],
  'skip': 0,
  'limit': 20,
  'total': total,
};

DiscoverGroupsPage _typed(List<String> ids, {required int skip, required int total}) {
  return DiscoverGroupsPage(
    groups: [
      for (final id in ids)
        GroupProfileModel.fromJson({'id': id, 'slug': id}).toEntity(),
    ],
    skip: skip,
    limit: 20,
    total: total,
  );
}

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
    store.entries[key] = jsonEncode(_json(['g1', 'g2'], total: 10));
    container = ProviderContainer(
      overrides: [
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        connectRepositoryProvider.overrideWithValue(
          ConnectRepositoryImpl(remote: remote, store: store),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(discoverGroupsProvider, (_, __) {});
  });

  List<String> ids() =>
      container.read(discoverGroupsProvider).groups.map((g) => g.id).toList();

  test('loadMore waits while the first page is still being refreshed', () async {
    final notifier = container.read(discoverGroupsProvider.notifier);
    expect(ids(), ['g1', 'g2']);
    notifier.ensureLoaded();
    await pumpEventQueue();

    await notifier.loadMore();
    expect(remote.nextPageCalls, 0);

    remote.firstPage.complete(_json(['g1', 'g9'], total: 10));
    await pumpEventQueue();
    expect(ids(), ['g1', 'g9']);
  });

  test('a page fetched against an older first page is dropped', () async {
    final notifier = container.read(discoverGroupsProvider.notifier);
    notifier.ensureLoaded();
    remote.firstPage.complete(_json(['g1', 'g2'], total: 10));
    await pumpEventQueue();

    final pageTwo = notifier.loadMore();
    await pumpEventQueue();
    expect(remote.nextPageCalls, 1);

    // A fresh first page lands while page two is still in flight.
    remote.firstPage = Completer()..complete(_json(['g1', 'g2', 'g3'], total: 10));
    await notifier.loadInitial();
    expect(ids(), ['g1', 'g2', 'g3']);

    remote.nextPage.complete(_typed(['g3', 'g4'], skip: 2, total: 10));
    await pageTwo;
    expect(ids(), ['g1', 'g2', 'g3']);
    expect(container.read(discoverGroupsProvider).isLoadingMore, isFalse);
  });
}
