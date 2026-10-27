import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';

/// Domain contract for the remote routine API.
///
/// All methods return [Either<Failure, T>] so callers never deal with raw
/// exceptions across the layer boundary.
///
/// Implementation: [RoutineApiRepositoryImpl] in data/repositories/.
abstract class RoutineApiRepository {
  /// Fetches the authenticated user's routine.
  /// Returns [Right(null)] when no routine has been created yet (404 / 400
  /// "no routine" from the backend).
  Future<Either<Failure, RoutineData?>> getUserRoutine({
    required String language,
    int skip = 0,
    int limit = 20,
  });

  /// Stored routine first, then revalidated in the background.
  Stream<Either<Failure, RoutineData>> watchUserRoutine({
    required String language,
  });

  Future<Either<Failure, RoutineData>> refreshUserRoutine({
    required String language,
  });

  /// Creates a new routine with its first time block.
  /// Returns the server-assigned [routineId] and [timeBlockId] on success.
  Future<Either<Failure, ({String routineId, String timeBlockId})>>
      createRoutineWithTimeBlock(TimeBlockRequest request);

  /// Adds a time block to an existing routine.
  /// Returns the server-assigned [timeBlockId] of the new block.
  Future<Either<Failure, String>> createTimeBlock(
    String routineId,
    TimeBlockRequest request,
  );

  /// Fully replaces a time block (time + sessions).
  Future<Either<Failure, void>> updateTimeBlock(
    String routineId,
    String timeBlockId,
    TimeBlockRequest request,
  );

  /// Soft-deletes a time block.
  Future<Either<Failure, void>> deleteTimeBlock(
    String routineId,
    String timeBlockId,
  );
}
