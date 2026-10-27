import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/series_remote_datasource.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/repositories/practice_explore_repository.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitations_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitations_page_response.dart';
import 'package:flutter_pecha/features/timer/data/datasource/timers_remote_datasource.dart';
import 'package:flutter_pecha/features/timer/data/models/preset_timer_model.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/fake_screen_cache_store.dart';

class _FakeTimers extends TimersRemoteDatasource {
  _FakeTimers() : super(dio: Dio());

  List<PresetTimerModel> timers = const [];
  Exception? error;

  @override
  Future<List<PresetTimerModel>> fetchPresetTimers({
    int skip = 0,
    int limit = 20,
  }) async {
    if (error != null) throw error!;
    return timers;
  }
}

class _FakeRecitations extends RecitationsRemoteDatasource {
  @override
  Future<RecitationsPageResponse> fetchRecitationsPage({
    RecitationsQueryParams? queryParams,
  }) async => throw UnimplementedError();
}

PresetTimerModel _timer(String id, int ms) =>
    PresetTimerModel(id: id, name: 'Timer $id', durationMs: ms);

List<int> _durations(Either<Failure, List<PresetTimer>> e) =>
    e.fold((_) => const [], (list) => list.map((t) => t.durationMs).toList());

void main() {
  late FakeScreenCacheStore store;
  late _FakeTimers timers;
  late PracticeExploreRepository repo;
  final key = ScreenCacheKey.public('practice_explore_timers', language: 'all');

  setUp(() {
    store = FakeScreenCacheStore();
    timers = _FakeTimers();
    repo = PracticeExploreRepository(
      store: store,
      seriesRemote: SeriesRemoteDatasource(dio: Dio()),
      recitationsRemote: _FakeRecitations(),
      malaRemote: MalaRemoteDataSource(dio: Dio()),
      timersRemote: timers,
    );
  });

  test('stored timers show first, then the changed server list sorted', () async {
    store.entries[key] = jsonEncode([_timer('a', 60000).toJson()]);
    timers.timers = [_timer('b', 120000), _timer('a', 60000)];

    final events = <Either<Failure, List<PresetTimer>>>[];
    final sub = repo.watchTimers().listen(events.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    expect(events.map(_durations), [
      [60000],
      [60000, 120000],
    ]);
  });

  test('a failed refresh keeps the stored timers', () async {
    store.entries[key] = jsonEncode([_timer('a', 60000).toJson()]);
    timers.error = const NetworkException('offline');

    final events = <Either<Failure, List<PresetTimer>>>[];
    final sub = repo.watchTimers().listen(events.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    expect(events.map(_durations), [
      [60000],
    ]);
  });
}
