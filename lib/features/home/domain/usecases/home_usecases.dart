import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/daily_quote.dart';
import 'package:flutter_pecha/features/home/domain/entities/featured_content.dart';
import 'package:flutter_pecha/features/home/domain/entities/prayer.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

export 'get_tags_usecase.dart';

/// Get daily prayer use case.
///
/// NOTE: This is a placeholder use case. The HomeRepository interface
/// for daily prayers does not yet exist. When a DailyPrayerRepositoryInterface
/// is created, update this use case to depend on it.
class GetDailyPrayerUseCase extends UseCase<Prayer, NoParams> {
  // Placeholder - not yet wired to a repository
  GetDailyPrayerUseCase();

  @override
  Future<Either<Failure, Prayer>> call(NoParams params) async {
    return Left(UnknownFailure('Daily prayer feature not yet implemented'));
  }
}

/// Get daily quote use case.
///
/// NOTE: This is a placeholder use case. The HomeRepository interface
/// for daily quotes does not yet exist. When a DailyQuoteRepositoryInterface
/// is created, update this use case to depend on it.
class GetDailyQuoteUseCase extends UseCase<DailyQuote, NoParams> {
  // Placeholder - not yet wired to a repository
  GetDailyQuoteUseCase();

  @override
  Future<Either<Failure, DailyQuote>> call(NoParams params) async {
    return Left(UnknownFailure('Daily quote feature not yet implemented'));
  }
}

/// Get featured content use case.
///
/// NOTE: This is a placeholder use case. The HomeRepository interface
/// for featured content does not yet exist. When a FeaturedContentRepositoryInterface
/// is created, update this use case to depend on it.
class GetFeaturedContentUseCase extends UseCase<List<FeaturedContent>, NoParams> {
  // Placeholder - not yet wired to a repository
  GetFeaturedContentUseCase();

  @override
  Future<Either<Failure, List<FeaturedContent>>> call(NoParams params) async {
    return Left(UnknownFailure('Featured content feature not yet implemented'));
  }
}
