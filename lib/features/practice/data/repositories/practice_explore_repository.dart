import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_key.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_store.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/series_remote_datasource.dart';
import 'package:flutter_pecha/features/home/data/models/series_model.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_remote_datasource.dart';
import 'package:flutter_pecha/features/mala/data/models/accumulator_model.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitations_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitations_page_response.dart';
import 'package:flutter_pecha/features/timer/data/datasource/timers_remote_datasource.dart';
import 'package:flutter_pecha/features/timer/data/models/preset_timer_model.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:fpdart/fpdart.dart';

const int practiceExploreRecitationsPreviewLimit = 2;

/// The four Explore sections, each stored per language and revalidated.
class PracticeExploreRepository {
  PracticeExploreRepository({
    required this.store,
    required this.seriesRemote,
    required this.recitationsRemote,
    required this.malaRemote,
    required this.timersRemote,
  });

  final ScreenCacheStore store;
  final SeriesRemoteDatasource seriesRemote;
  final RecitationsRemoteDatasource recitationsRemote;
  final MalaRemoteDataSource malaRemote;
  final TimersRemoteDatasource timersRemote;

  Stream<Either<Failure, List<Series>>> watchSeries(String language) =>
      seriesSource(language).watch();
  Future<Either<Failure, List<Series>>> refreshSeries(String language) =>
      seriesSource(language).refresh();

  Stream<Either<Failure, RecitationsPageResponse>> watchRecitations(
    String language,
  ) => recitationsSource(language).watch();
  Future<Either<Failure, RecitationsPageResponse>> refreshRecitations(
    String language,
  ) => recitationsSource(language).refresh();

  Stream<Either<Failure, List<Mantra>>> watchAccumulators(String language) =>
      accumulatorsSource(language).watch();
  Future<Either<Failure, List<Mantra>>> refreshAccumulators(String language) =>
      accumulatorsSource(language).refresh();

  Stream<Either<Failure, List<PresetTimer>>> watchTimers() => timersSource().watch();
  Future<Either<Failure, List<PresetTimer>>> refreshTimers() =>
      timersSource().refresh();

  // Sources are public so providers can seed the first frame synchronously.
  ScreenCacheSource<List<Series>> seriesSource(String language) {
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.public('practice_explore_series', language: language),
      fetchJson: () async {
        final models = await seriesRemote.fetchSeries(
          params: SeriesQueryParams(language: language),
        );
        return models.map((m) => m.toJson()).toList();
      },
      fromJson:
          (json) =>
              (json as List)
                  .map(
                    (e) => SeriesModel.fromJson(
                      e as Map<String, dynamic>,
                    ).toEntity(language: language),
                  )
                  .toList(),
      failureMessage: 'Failed to load plans',
    );
  }

  ScreenCacheSource<RecitationsPageResponse> recitationsSource(String language) {
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.public(
        'practice_explore_recitations',
        language: language,
      ),
      fetchJson: () async {
        final page = await recitationsRemote.fetchRecitationsPage(
          queryParams: RecitationsQueryParams(
            language: language,
            skip: 0,
            limit: practiceExploreRecitationsPreviewLimit,
            noCache: true,
          ),
        );
        return page.toJson();
      },
      fromJson:
          (json) =>
              RecitationsPageResponse.fromJson(json as Map<String, dynamic>),
      failureMessage: 'Failed to load chants',
    );
  }

  ScreenCacheSource<List<Mantra>> accumulatorsSource(String language) {
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.public(
        'practice_explore_accumulators',
        language: language,
      ),
      fetchJson: () async {
        final models = await malaRemote.fetchPresets(language: language);
        return models.map((m) => m.toJson()).toList();
      },
      fromJson:
          (json) =>
              (json as List)
                  .map(
                    (e) =>
                        PresetAccumulatorModel.fromJson(
                          e as Map<String, dynamic>,
                        ).toEntity(),
                  )
                  .toList(),
      failureMessage: 'Failed to load accumulations',
    );
  }

  // `/timers` carries the signed-in user's own timers, so the key is theirs.
  ScreenCacheSource<List<PresetTimer>> timersSource() {
    return ScreenCacheSource(
      store: store,
      key: ScreenCacheKey.user(
        'practice_explore_timers',
        userId: store.currentUserIdSync,
        language: 'all',
      ),
      fetchJson: () async {
        final models = await timersRemote.fetchPresetTimers();
        return models.map((m) => m.toJson()).toList();
      },
      fromJson:
          (json) =>
              (json as List)
                  .map(
                    (e) =>
                        PresetTimerModel.fromJson(
                          e as Map<String, dynamic>,
                        ).toEntity(),
                  )
                  .toList()
                ..sort((a, b) => a.durationMs.compareTo(b.durationMs)),
      failureMessage: 'Failed to load timers',
    );
  }
}
