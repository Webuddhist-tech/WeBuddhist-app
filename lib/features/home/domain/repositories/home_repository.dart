import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/home/domain/entities/routine_info.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/home/domain/entities/today_event.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';
import 'package:flutter_pecha/features/home/domain/entities/verse_of_day_engagement.dart';
import 'package:flutter_pecha/features/plans/data/models/response/featured_day_response.dart';
import 'package:flutter_pecha/shared/domain/base_classes/repository.dart';

/// Featured day repository interface.
abstract class FeaturedDayRepositoryInterface extends Repository {
  Future<Either<Failure, FeaturedDayResponse>> getFeaturedDay({
    String? language,
  });
  Stream<Either<Failure, FeaturedDayResponse>> watchFeaturedDay({
    String? language,
  });

  /// Convert FeaturedDayResponse tasks to List of FeaturedDayTask
  List<FeaturedDayTask> mapToFeaturedDayTasks(FeaturedDayResponse response);
}

/// Tags repository interface.
abstract class TagsRepositoryInterface extends Repository {
  Future<Either<Failure, List<String>>> getTags({required String language});
  Stream<Either<Failure, List<String>>> watchTags({required String language});
}

/// Verse of the Day repository interface.
abstract class VerseOfDayRepositoryInterface extends Repository {
  Future<Either<Failure, VerseOfDay>> getVerseOfDay({required String language});
  Stream<Either<Failure, VerseOfDay>> watchVerseOfDay({
    required String language,
  });
  Future<Either<Failure, VerseOfDayLikes>> getLikes(String verseId);
  Future<Either<Failure, Unit>> likeVerse(String verseId);
  Future<Either<Failure, Unit>> unlikeVerse(String verseId);
  Future<Either<Failure, VerseOfDayLikersPage>> getLikers({
    required String verseId,
    int skip = 0,
    int limit = 20,
  });
  Future<Either<Failure, VerseOfDayCommentsPage>> getComments({
    required String verseId,
    int skip = 0,
    int limit = 20,
  });
  Future<Either<Failure, VerseOfDayComment>> getComment({
    required String verseId,
    required String commentId,
  });
  Future<Either<Failure, VerseOfDayComment>> createComment({
    required String verseId,
    required String text,
    String? parentCommentId,
  });
  Future<Either<Failure, Unit>> deleteComment(String commentId);
  Future<Either<Failure, Unit>> likeComment(String commentId);
  Future<Either<Failure, Unit>> unlikeComment(String commentId);
}

/// Today's events repository interface.
abstract class TodayEventsRepositoryInterface extends Repository {
  Future<Either<Failure, List<TodayEvent>>> getTodayEvents({
    required String language,
  });
  Stream<Either<Failure, List<TodayEvent>>> watchTodayEvents({
    required String language,
  });
}

/// Routine info repository interface.
abstract class RoutineInfoRepositoryInterface extends Repository {
  Future<Either<Failure, RoutineInfo>> getRoutineInfo();
  Stream<Either<Failure, RoutineInfo>> watchRoutineInfo();
}

/// User streak repository interface.
abstract class StreakRepositoryInterface extends Repository {
  Future<Either<Failure, int>> getStreak();
  Stream<Either<Failure, int>> watchStreak();
}

/// Series repository interface.
abstract class SeriesRepositoryInterface extends Repository {
  Future<Either<Failure, List<Series>>> getFeaturedSeries({
    required String language,
    int limit = 10,
  });
  Stream<Either<Failure, List<Series>>> watchFeaturedSeries({
    required String language,
    int limit = 10,
  });
  Future<Either<Failure, List<Series>>> getSeriesList({
    required String language,
  });
  Stream<Either<Failure, List<Series>>> watchSeriesList({
    required String language,
  });
  Future<Either<Failure, Series>> getSeriesById(
    String id, {
    required String language,
  });
  Stream<Either<Failure, Series>> watchSeriesById(
    String id, {
    required String language,
  });

  /// Enrolls the authenticated user in the given series.
  /// Backend auto-enrolls the user in all plans that belong to the series.
  Future<Either<Failure, Unit>> enrollInSeries(
    String seriesId, {
    String? groupId,
  });

  /// Returns the set of series IDs the authenticated user is enrolled in.
  /// Used to suppress the Enroll button for already-enrolled series.
  Future<Either<Failure, Set<String>>> getUserSeriesEnrollments();
  Stream<Either<Failure, Set<String>>> watchUserSeriesEnrollments();
  Future<void> flushPendingEnrollments();
}
