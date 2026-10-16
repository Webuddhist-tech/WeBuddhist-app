import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/feedback/data/datasource/feedback_remote_datasource.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/feedback_report.dart';
import 'package:flutter_pecha/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:fpdart/fpdart.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  FeedbackRepositoryImpl({required this.remote});

  final FeedbackRemoteDatasource remote;

  @override
  Future<Either<Failure, void>> submit(FeedbackReport report) async {
    try {
      await remote.submit(report);
      return const Right(null);
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'submitFeedback'));
    }
  }
}
