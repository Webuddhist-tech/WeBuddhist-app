import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/more/data/datasource/user_stats_local_datasource.dart';
import 'package:flutter_pecha/features/more/data/datasource/user_stats_remote_datasource.dart';
import 'package:flutter_pecha/features/more/data/repositories/user_stats_repository_impl.dart';
import 'package:flutter_pecha/features/more/domain/entities/mantra_count.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FakeRemote extends UserStatsRemoteDatasource {
  _FakeRemote() : super(dio: Dio());

  List<int> counts = const [];
  Exception? error;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> fetchMantraCountsJson({
    required String language,
    int skip = 0,
    int limit = 20,
  }) async {
    calls++;
    if (error != null) throw error!;
    return _page(counts);
  }
}

Map<String, dynamic> _page(List<int> counts) => {
  'counts': [
    for (final c in counts)
      {'mantra_id': 'm$c', 'mantra_title': 'Mantra $c', 'total_count': c},
  ],
};

List<int> _totals(Either<Failure, MantraCountPage> e) =>
    e.fold((_) => const [], (page) => page.counts.map((c) => c.totalCount).toList());

void main() {
  late FakeScreenCacheStore store;
  late _FakeRemote remote;
  late UserStatsRepositoryImpl repo;
  final key = ScreenCacheKey.user('mantra_counts', userId: 'user-1', language: 'en');

  setUp(() {
    store = FakeScreenCacheStore();
    remote = _FakeRemote();
    repo = UserStatsRepositoryImpl(
      remote: remote,
      local: UserStatsLocalDatasource(),
      store: store,
    );
  });

  test('watch yields the stored counts, then the changed ones', () async {
    store.entries[key] = jsonEncode(_page([1]));
    remote.counts = [1, 2];

    final events = <Either<Failure, MantraCountPage>>[];
    final sub = repo.watchMantraCounts(language: 'en').listen(events.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    expect(events.map(_totals), [
      [1],
      [1, 2],
    ]);
    expect(remote.calls, 1);
  });

  test('a failed refresh keeps the stored counts silently', () async {
    store.entries[key] = jsonEncode(_page([5]));
    remote.error = const NetworkException('offline');

    final events = <Either<Failure, MantraCountPage>>[];
    final sub = repo.watchMantraCounts(language: 'en').listen(events.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    expect(events.map(_totals), [
      [5],
    ]);
  });

  test('refresh returns the failure when nothing can be loaded', () async {
    remote.error = const NetworkException('offline');
    final result = await repo.refreshMantraCounts(language: 'en');
    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
  });
}
