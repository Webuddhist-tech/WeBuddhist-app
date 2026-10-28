import 'package:flutter_pecha/core/cache/screen_cache/screen_cache_source.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/more/domain/entities/mantra_count.dart';
import 'package:flutter_pecha/features/more/domain/entities/series_day_completed.dart';
import 'package:flutter_pecha/features/more/domain/entities/user_stats.dart';
import 'package:flutter_pecha/features/more/domain/usecases/get_mantra_counts_usecase.dart';
import 'package:flutter_pecha/features/more/domain/usecases/get_series_day_completed_usecase.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

abstract class UserStatsRepositoryInterface extends Repository {
  Future<Either<Failure, UserStats>> getUserStats();
  Stream<Either<Failure, UserStats>> watchUserStats();
  Future<Either<Failure, UserStats>> refreshUserStats();

  Future<Either<Failure, SeriesDayCompletedPage>> getSeriesDayCompleted(
    GetSeriesDayCompletedParams params,
  );

  Future<Either<Failure, MantraCountPage>> getMantraCounts(
    GetMantraCountsParams params,
  );

  /// Stored first page first, then revalidated in the background.
  Stream<Either<Failure, SeriesDayCompletedPage>> watchSeriesDayCompleted({
    required String language,
  });

  Future<Either<Failure, SeriesDayCompletedPage>> refreshSeriesDayCompleted({
    required String language,
  });

  Stream<Either<Failure, MantraCountPage>> watchMantraCounts({
    required String language,
  });

  /// Synchronous builders so a screen can seed its first frame.
  ScreenCacheSource<SeriesDayCompletedPage> seriesDayCompletedSource({
    required String language,
  });

  ScreenCacheSource<MantraCountPage> mantraCountsSource({
    required String language,
  });

  Future<Either<Failure, MantraCountPage>> refreshMantraCounts({
    required String language,
  });
}
