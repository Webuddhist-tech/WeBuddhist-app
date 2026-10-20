import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/feedback_receipt.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/feedback_report.dart';
import 'package:fpdart/fpdart.dart';

abstract class FeedbackRepository {
  /// Stores [report] for the signed-in user. Success means the backend saved
  /// it, not that its Discord copy went out: that happens afterwards and is
  /// never reported back.
  Future<Either<Failure, FeedbackReceipt>> submit(FeedbackReport report);
}
