import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';

abstract class TimersRepositoryInterface {
  Future<Either<Failure, List<PresetTimer>>> getPresetTimers({
    int skip,
    int limit,
  });

  Stream<Either<Failure, List<PresetTimer>>> watchPresetTimers({
    int skip,
    int limit,
  });

  Future<Either<Failure, List<PresetTimer>>> refreshPresetTimers({
    int skip,
    int limit,
  });

  /// Creates a user-defined timer (`POST /timers/user`) and refreshes the
  /// cached preset timer list so it shows up under "Your timers".
  Future<Either<Failure, PresetTimer>> createUserTimer({
    required String name,
    required String description,
    required int durationMs,
    String? ambientSoundId,
    required bool bellAtStart,
    required bool bellAtEnd,
  });

  /// Deletes a user-defined timer (`DELETE /timers/user/{timerId}`) and
  /// refreshes the cached preset timer list.
  Future<Either<Failure, void>> deleteUserTimer({required String timerId});

  Future<Either<Failure, void>> stopUserTimer({
    required String timerId,
    required int durationMs,
  });

  Future<void> flushPendingTimerStops();
}
