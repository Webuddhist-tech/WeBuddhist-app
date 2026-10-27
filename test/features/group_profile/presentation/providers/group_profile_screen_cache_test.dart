import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_accumulator_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/datasource/group_profile_remote_datasource.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_accumulator_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/data/repositories/group_profile_repository_impl.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

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

class _FakeProfileRemote extends GroupProfileRemoteDatasource {
  _FakeProfileRemote() : super(dio: Dio());

  List<String> eventIds = const [];
  List<String> practiceIds = const [];
  Exception? error;
  int eventCalls = 0;
  int practiceCalls = 0;

  @override
  Future<Map<String, dynamic>> fetchGroupEventsJson(
    String groupId, {
    required String language,
  }) async {
    eventCalls++;
    if (error != null) throw error!;
    return _eventsPage(eventIds);
  }

  @override
  Future<Map<String, dynamic>> fetchPracticesJson({
    String? groupId,
    required bool includeUnfollowed,
    required String language,
    required int skip,
    required int limit,
  }) async {
    practiceCalls++;
    if (error != null) throw error!;
    return _practicesPage(practiceIds);
  }
}

class _FakeAccumulatorRemote extends GroupAccumulatorRemoteDatasource {
  _FakeAccumulatorRemote() : super(dio: Dio());

  int total = 10;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> fetchGroupAccumulatorJson(
    String accumulatorId, {
    required String language,
  }) async {
    calls++;
    return _accumulator(accumulatorId, total: total);
  }
}

Map<String, dynamic> _eventsPage(List<String> ids) => {
  'events': [
    for (final id in ids)
      {'id': id, 'group_id': 'g1', 'title': id, 'start_date': '2026-01-01'},
  ],
  'total': ids.length,
  'skip': 0,
  'limit': 20,
};

Map<String, dynamic> _practicesPage(List<String> ids) => {
  'practices': [
    for (final id in ids) {'type': 'SERIES', 'group_name': id},
  ],
  'total': ids.length,
  'skip': 0,
  'limit': 20,
};

Map<String, dynamic> _accumulator(String id, {required int total}) => {
  'id': id,
  'group_id': 'g1',
  'title': 'Health',
  'target_count': 100,
  'total_count': total,
};

List<String> _eventIds(AsyncValue<Either<Failure, GroupEventsPage>> value) =>
    value.valueOrNull?.fold(
      (_) => const <String>[],
      (page) => page.events.map((e) => e.id).toList(),
    ) ??
    const [];

void main() {
  late FakeScreenCacheStore store;
  late _FakeProfileRemote profileRemote;
  late _FakeAccumulatorRemote accumulatorRemote;

  setUp(() {
    store = FakeScreenCacheStore();
    profileRemote = _FakeProfileRemote();
    accumulatorRemote = _FakeAccumulatorRemote();
  });

  ProviderContainer build() {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _SignedInAuth()),
        contentLanguageProvider.overrideWith((ref) => _FixedContentLanguage()),
        groupProfileRepositoryProvider.overrideWithValue(
          GroupProfileRepositoryImpl(remote: profileRemote, store: store),
        ),
        groupAccumulatorRepositoryProvider.overrideWithValue(
          GroupAccumulatorRepositoryImpl(
            remote: accumulatorRemote,
            store: store,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('group events: stored page first, then the refreshed one', () async {
    final key = ScreenCacheKey.user(
      'group_events',
      userId: 'user-1',
      language: 'en',
      params: ['g1'],
    );
    store.entries[key] = jsonEncode(_eventsPage(['e1']));
    profileRemote.eventIds = ['e1', 'e2'];
    final container = build();

    final seen = <List<String>>[];
    container.listen(groupEventsProvider('g1'), (_, next) {
      if (next.hasValue) seen.add(_eventIds(next));
    }, fireImmediately: true);
    await pumpEventQueue();

    expect(seen, [
      ['e1'],
      ['e1', 'e2'],
    ]);
    expect(profileRemote.eventCalls, 1);
  });

  test('group events: offline with a stored page stays on it', () async {
    final key = ScreenCacheKey.user(
      'group_events',
      userId: 'user-1',
      language: 'en',
      params: ['g1'],
    );
    store.entries[key] = jsonEncode(_eventsPage(['e1']));
    profileRemote.error = const NetworkException('offline');
    final container = build();

    container.listen(groupEventsProvider('g1'), (_, __) {});
    await pumpEventQueue();
    expect(_eventIds(container.read(groupEventsProvider('g1'))), ['e1']);
  });

  test('accumulator detail: refresh pushes the server copy to the stream',
      () async {
    final container = build();
    final seen = <int?>[];
    container.listen(groupAccumulatorDetailProvider('a1'), (_, next) {
      if (next.hasValue) {
        seen.add(
          next.valueOrNull?.fold((_) => null, (d) => d.totalCount),
        );
      }
    }, fireImmediately: true);
    await pumpEventQueue();
    expect(seen, [10]);

    accumulatorRemote.total = 12;
    final result = await container
        .read(groupAccumulatorRepositoryProvider)
        .refreshGroupAccumulator('a1', language: 'en');
    await pumpEventQueue();
    expect(result.fold((_) => null, (d) => d.totalCount), 12);
    expect(seen, [10, 12]);
  });

  test('practices: the stored first page shows without a loading flag',
      () async {
    final key = ScreenCacheKey.user(
      'group_practices',
      userId: 'user-1',
      language: 'en',
      params: ['g1'],
    );
    store.entries[key] = jsonEncode(_practicesPage(['p1']));
    profileRemote.practiceIds = ['p1', 'p2'];
    final container = build();

    final seen = <(List<String?>, bool)>[];
    container.listen(groupPracticesProvider('g1'), (_, next) {
      seen.add((next.practices.map((p) => p.groupName).toList(), next.isLoading));
    }, fireImmediately: true);
    await pumpEventQueue();

    expect(seen.any((s) => s.$1.isEmpty && s.$2), isFalse);
    expect(seen.first.$1, isEmpty);
    expect(seen.last.$1, ['p1', 'p2']);
    expect(seen.last.$2, isFalse);
    expect(profileRemote.practiceCalls, 1);
  });

  test('practices: a failed refresh keeps the stored page silently', () async {
    final key = ScreenCacheKey.user(
      'group_practices',
      userId: 'user-1',
      language: 'en',
      params: ['g1'],
    );
    store.entries[key] = jsonEncode(_practicesPage(['p1']));
    profileRemote.error = const NetworkException('offline');
    final container = build();

    container.listen(groupPracticesProvider('g1'), (_, __) {});
    await pumpEventQueue();
    final state = container.read(groupPracticesProvider('g1'));
    expect(state.practices.map((p) => p.groupName), ['p1']);
    expect(state.error, isNull);
    expect(state.isLoading, isFalse);
  });
}
