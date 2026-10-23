import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class UpdateUserTimerParams extends Equatable {
  const UpdateUserTimerParams({
    required this.timerId,
    required this.name,
    required this.description,
    required this.durationMs,
    required this.ambientSoundId,
  });

  final String timerId;
  final String name;

  /// The user-typed title. Empty clears it.
  final String description;
  final int durationMs;

  /// Null clears the timer's ambient sound.
  final String? ambientSoundId;

  @override
  List<Object?> get props => [
    timerId,
    name,
    description,
    durationMs,
    ambientSoundId,
  ];
}

class UpdateUserTimerUseCase
    extends UseCase<PresetTimer, UpdateUserTimerParams> {
  UpdateUserTimerUseCase(this._updateUserTimer);

  final Future<Either<Failure, PresetTimer>> Function({
    required String timerId,
    required String name,
    required String description,
    required int durationMs,
    required String? ambientSoundId,
  })
  _updateUserTimer;

  @override
  Future<Either<Failure, PresetTimer>> call(
    UpdateUserTimerParams params,
  ) async {
    if (params.timerId.isEmpty) {
      return const Left(ValidationFailure('Timer ID cannot be empty'));
    }
    if (params.durationMs <= 0) {
      return const Left(ValidationFailure('Duration must be greater than 0'));
    }
    return _updateUserTimer(
      timerId: params.timerId,
      name: params.name,
      description: params.description,
      durationMs: params.durationMs,
      ambientSoundId: params.ambientSoundId,
    );
  }
}
