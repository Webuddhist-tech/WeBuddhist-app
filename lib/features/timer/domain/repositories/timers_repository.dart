import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';

/// Page size for `GET /timers`.
///
/// The endpoint caps `limit` at 100 and the app does not page, so one request
/// has to cover the presets *and* every timer the user created — take the
/// largest page the server allows rather than its default of 20.
const int kTimersPageLimit = 100;

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
  });

  /// Updates a user-defined timer (`PUT /timers/user/{timerId}`) and refreshes
  /// the cached preset timer list. A null [ambientSoundId] clears the sound.
  Future<Either<Failure, PresetTimer>> updateUserTimer({
    required String timerId,
    required String name,
    required int durationMs,
    required String? ambientSoundId,
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
