import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class CreateUserTimerParams extends Equatable {
  const CreateUserTimerParams({
    required this.name,
    required this.description,
    required this.durationMs,
    this.ambientSoundId,
    required this.bellAtStart,
    required this.bellAtEnd,
  });

  final String name;
  final String description;
  final int durationMs;
  final String? ambientSoundId;
  final bool bellAtStart;
  final bool bellAtEnd;

  @override
  List<Object?> get props => [
    name,
    description,
    durationMs,
    ambientSoundId,
    bellAtStart,
    bellAtEnd,
  ];
}

class CreateUserTimerUseCase
    extends UseCase<PresetTimer, CreateUserTimerParams> {
  CreateUserTimerUseCase(this._createUserTimer);

  final Future<Either<Failure, PresetTimer>> Function({
    required String name,
    required String description,
    required int durationMs,
    String? ambientSoundId,
    required bool bellAtStart,
    required bool bellAtEnd,
  })
  _createUserTimer;

  @override
  Future<Either<Failure, PresetTimer>> call(
    CreateUserTimerParams params,
  ) async {
    if (params.durationMs <= 0) {
      return const Left(ValidationFailure('Duration must be greater than 0'));
    }
    return _createUserTimer(
      name: params.name,
      description: params.description,
      durationMs: params.durationMs,
      ambientSoundId: params.ambientSoundId,
      bellAtStart: params.bellAtStart,
      bellAtEnd: params.bellAtEnd,
    );
  }
}
