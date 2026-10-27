import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/connect/data/datasource/connect_remote_datasource.dart';
import 'package:flutter_pecha/features/connect/data/repositories/connect_repository_impl.dart';
import 'package:flutter_pecha/features/connect/domain/entities/discover_groups_page.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
  Future<Map<String, dynamic>> fetchMyGroupsJson({
    required String language,
    int skip = 0,
    int limit = 20,
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

List<String> _ids(AsyncValue<DiscoverGroupsPage> value) =>
    value.valueOrNull?.groups.map((g) => g.id).toList() ?? const [];

void main() {
  late FakeScreenCacheStore store;
  late _FakeRemote remote;
  final key = ScreenCacheKey.user('my_groups', userId: 'user-1', language: 'en');

  setUp(() {
    store = FakeScreenCacheStore();
    remote = _FakeRemote();
  });

  ProviderContainer build({bool guest = false}) {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _Auth(AuthState(isLoggedIn: !guest, isGuest: guest)),
        ),
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        connectRepositoryProvider.overrideWithValue(
          ConnectRepositoryImpl(remote: remote, store: store),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('guests get an empty page without a request', () async {
    final container = build(guest: true);
    container.listen(myGroupsProvider, (_, __) {});
    await pumpEventQueue();
    expect(_ids(container.read(myGroupsProvider)), isEmpty);
    expect(remote.calls, 0);
  });

  test('stored page shows first, then the refreshed one', () async {
    store.entries[key] = jsonEncode(_page(['g1']));
    remote.response = _page(['g1', 'g2']);
    final container = build();

    final seen = <List<String>>[];
    container.listen(myGroupsProvider, (_, next) {
      if (next.hasValue) seen.add(_ids(next));
    }, fireImmediately: true);
    await pumpEventQueue();

    expect(seen, [
      ['g1'],
      ['g1', 'g2'],
    ]);
    expect(store.entries[key], jsonEncode(_page(['g1', 'g2'])));
  });

  test('a failure with nothing stored becomes an error state', () async {
    remote.error = const NetworkException('offline');
    final container = build();
    container.listen(myGroupsProvider, (_, __) {});
    await pumpEventQueue();
    expect(container.read(myGroupsProvider).hasError, isTrue);
  });

  test('pending joins and unjoins reconcile against the stored page', () async {
    store.entries[key] = jsonEncode(_page(['g1', 'g2']));
    remote.error = const NetworkException('offline');
    final container = build();
    container.read(pendingJoinedGroupsProvider.notifier).state = [
      GroupProfileModel.fromJson({'id': 'g2', 'slug': 'g2'}).toEntity(),
      GroupProfileModel.fromJson({'id': 'g9', 'slug': 'g9'}).toEntity(),
    ];
    container.read(pendingUnjoinedGroupIdsProvider.notifier).state = {'g1', 'zz'};

    container.listen(myGroupsProvider, (_, __) {});
    await pumpEventQueue();

    expect(
      container.read(pendingJoinedGroupsProvider).map((g) => g.id),
      ['g9'],
    );
    expect(container.read(pendingUnjoinedGroupIdsProvider), {'g1'});
  });
}
