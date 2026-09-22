import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_pecha/features/timer/domain/repositories/timers_repository.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class GetPresetTimersParams {
  const GetPresetTimersParams({this.skip = 0, this.limit = kTimersPageLimit});

  final int skip;
  final int limit;
}

class GetPresetTimersUseCase
    extends UseCase<List<PresetTimer>, GetPresetTimersParams> {
  GetPresetTimersUseCase(this._getPresetTimers);

  final Future<Either<Failure, List<PresetTimer>>> Function({
    int skip,
    int limit,
  })
  _getPresetTimers;

  @override
  Future<Either<Failure, List<PresetTimer>>> call(
    GetPresetTimersParams params,
  ) async {
    return _getPresetTimers(skip: params.skip, limit: params.limit);
  }
}
