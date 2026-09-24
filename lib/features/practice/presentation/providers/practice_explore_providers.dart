import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/data/datasource/series_remote_datasource.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/mala/data/datasources/mala_remote_datasource.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitations_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitations_page_response.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_datasource_provider.dart';
import 'package:flutter_pecha/features/timer/data/datasource/timers_remote_datasource.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

final practiceExploreSeriesProvider =
    FutureProvider<Either<Failure, List<Series>>>((ref) async {
  final language = ref.watch(contentLanguageProvider);
  final dio = ref.watch(dioProvider);
  final datasource = SeriesRemoteDatasource(dio: dio);
  try {
    final models = await datasource.fetchSeries(
      params: SeriesQueryParams(language: language),
    );
    final entities =
        models.map((m) => m.toEntity(language: language)).toList();
    return Right(entities);
  } catch (e) {
    return Left(UnknownFailure('Failed to load plans: $e'));
  }
});

const int practiceExploreRecitationsPreviewLimit = 2;

final practiceExploreRecitationsProvider =
    FutureProvider<Either<Failure, RecitationsPageResponse>>((ref) async {
  final language = ref.watch(contentLanguageProvider);
  final datasource = ref.watch(recitationsRemoteDatasourceProvider);
  try {
    final page = await datasource.fetchRecitationsPage(
      queryParams: RecitationsQueryParams(
        language: language,
        skip: 0,
        limit: practiceExploreRecitationsPreviewLimit,
      ),
    );
    return Right(page);
  } catch (e) {
    return Left(UnknownFailure('Failed to load chants: $e'));
  }
});

final practiceExploreAccumulatorsProvider =
    FutureProvider<Either<Failure, List<Mantra>>>((ref) async {
  final language = ref.watch(contentLanguageProvider);
  final dio = ref.watch(dioProvider);
  final datasource = MalaRemoteDataSource(dio: dio);
  try {
    final models = await datasource.fetchPresets(language: language);
    final entities = models.map((m) => m.toEntity()).toList();
    return Right(entities);
  } catch (e) {
    return Left(UnknownFailure('Failed to load accumulations: $e'));
  }
});

final practiceExploreTimersProvider =
    FutureProvider<Either<Failure, List<PresetTimer>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final datasource = TimersRemoteDatasource(dio: dio);
  try {
    final models = await datasource.fetchPresetTimers();
    final entities = models.map((m) => m.toEntity()).toList()
      ..sort((a, b) => a.durationMs.compareTo(b.durationMs));
    return Right(entities);
  } catch (e) {
    return Left(UnknownFailure('Failed to load timers: $e'));
  }
});
