import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/shared/domain/base_classes/usecase.dart';

class DeleteUserTimerParams extends Equatable {
  const DeleteUserTimerParams({required this.timerId});

  final String timerId;

  @override
  List<Object?> get props => [timerId];
}

class DeleteUserTimerUseCase extends UseCase<void, DeleteUserTimerParams> {
  DeleteUserTimerUseCase(this._deleteUserTimer);

  final Future<Either<Failure, void>> Function({required String timerId})
  _deleteUserTimer;

  @override
  Future<Either<Failure, void>> call(DeleteUserTimerParams params) async {
    if (params.timerId.isEmpty) {
      return const Left(ValidationFailure('Timer ID cannot be empty'));
    }
    return _deleteUserTimer(timerId: params.timerId);
  }
}
