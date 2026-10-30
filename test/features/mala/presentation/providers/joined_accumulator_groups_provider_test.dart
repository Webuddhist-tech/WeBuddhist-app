import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_remote_datasource.dart';
import 'package:flutter_pecha/features/mala/data/repositories/mala_repository_impl.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _SignedInAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _SignedInAuth() : super(const AuthState(isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedContentLanguage extends StateNotifier<String>
    implements ContentLanguageNotifier {
  _FixedContentLanguage() : super('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemote extends MalaRemoteDataSource {
  _FakeRemote() : super(dio: Dio());

  List<String> groupIds = const [];
  Exception? error;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> fetchAccumulatorGroupsJson(
    String accumulatorId, {
    bool joinedOnly = false,
    String? language,
  }) async {
    calls++;
    if (error != null) throw error!;
    return _page(groupIds);
  }
}

Map<String, dynamic> _page(List<String> ids) => {
  'groups': [
    for (final id in ids)
      {'group_accumulator_id': id, 'group_id': 'g-$id', 'is_joined': true},
  ],
  'total': ids.length,
};

List<String> _ids(AsyncValue<List<AccumulatorGroup>> value) =>
    value.valueOrNull?.map((g) => g.groupAccumulatorId).toList() ?? const [];

void main() {
  late FakeScreenCacheStore store;
  late _FakeRemote remote;
  final key = ScreenCacheKey.user(
    'joined_accumulator_groups',
    userId: 'user-1',
    language: 'en',
    params: ['preset-1'],
  );

  setUp(() {
    store = FakeScreenCacheStore();
    remote = _FakeRemote();
  });

  ProviderContainer build() {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        malaRepositoryProvider.overrideWithValue(
          MalaRepositoryImpl(remote: remote, store: store),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('stored groups show first, then the refreshed ones', () async {
    store.entries[key] = jsonEncode(_page(['ga1']));
    remote.groupIds = ['ga1', 'ga2'];
    final container = build();

    final seen = <List<String>>[];
    container.listen(joinedAccumulatorGroupsProvider('preset-1'), (_, next) {
      if (next.hasValue) seen.add(_ids(next));
    }, fireImmediately: true);
    await pumpEventQueue();

    expect(seen, [
      ['ga1'],
      ['ga1', 'ga2'],
    ]);
    expect(remote.calls, 1);
  });

  test('stored groups are the state on the very first read', () async {
    store.entries[key] = jsonEncode(_page(['ga1']));
    remote.groupIds = ['ga1'];
    final container = build();
    container.listen(joinedAccumulatorGroupsProvider('preset-1'), (_, __) {});

    final first = container.read(joinedAccumulatorGroupsProvider('preset-1'));
    expect(first.isLoading, isFalse);
    expect(_ids(first), ['ga1']);
  });

  test('a failure with nothing stored is an empty list', () async {
    remote.error = const NetworkException('offline');
    final container = build();
    container.listen(joinedAccumulatorGroupsProvider('preset-1'), (_, __) {});
    await pumpEventQueue();
    final value = container.read(joinedAccumulatorGroupsProvider('preset-1'));
    expect(value.hasValue, isTrue);
    expect(_ids(value), isEmpty);
  });
}
