import 'dart:io';

import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/feedback/data/datasource/feedback_remote_datasource.dart';
import 'package:flutter_pecha/features/feedback/data/repositories/feedback_repository_impl.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/feedback_receipt.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/feedback_report.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/help_topic.dart';
import 'package:flutter_pecha/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FeedbackFailure { offline, rateLimited, tooLarge, unavailable, failed }

class FeedbackException implements Exception {
  const FeedbackException(this.failure, [this.cause]);

  final FeedbackFailure failure;
  final Object? cause;

  @override
  String toString() => 'FeedbackException($failure, $cause)';
}

/// Which message the sheet shows for a failed submit.
FeedbackFailure feedbackFailureOf(Failure failure) {
  return switch (failure) {
    NetworkFailure() => FeedbackFailure.offline,
    RateLimitFailure() => FeedbackFailure.rateLimited,
    ValidationFailure(code: FeedbackRemoteDatasource.tooLargeCode) =>
      FeedbackFailure.tooLarge,
    // No endpoint on this backend, or the backend is down.
    NotFoundFailure() || ServerFailure() => FeedbackFailure.unavailable,
    _ => FeedbackFailure.failed,
  };
}

final feedbackRemoteDatasourceProvider = Provider<FeedbackRemoteDatasource>((
  ref,
) {
  return FeedbackRemoteDatasource(dio: ref.watch(dioProvider));
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepositoryImpl(
    remote: ref.watch(feedbackRemoteDatasourceProvider),
  );
});

final sendFeedbackProvider = Provider<SendFeedback>(SendFeedback.new);

/// Attaches the app and device context to a message and sends it. Throws
/// [FeedbackException] on failure.
///
/// This is the whole of Help & contact's send: the backend also posts the
/// message into the user's WeBuddhist Team chat, so the app sends no chat
/// message of its own.
class SendFeedback {
  SendFeedback(this._ref);

  final Ref _ref;

  Future<FeedbackReceipt> call({
    required String message,
    List<String> imagePaths = const [],
    HelpTopic? topic,
  }) async {
    final result = await _ref
        .read(feedbackRepositoryProvider)
        .submit(
          FeedbackReport(
            message: message,
            imagePaths: imagePaths,
            appVersion: await _appVersion(),
            platform: _platform(),
            topic: topic,
          ),
        );
    return result.fold(
      (failure) => throw FeedbackException(feedbackFailureOf(failure), failure),
      (receipt) => receipt,
    );
  }

  Future<String> _appVersion() async {
    try {
      final info = await _ref.read(packageInfoProvider.future);
      if (info.version.isEmpty) return 'unknown';
      return info.buildNumber.isEmpty
          ? info.version
          : '${info.version} (${info.buildNumber})';
    } catch (_) {
      return 'unknown';
    }
  }

  String _platform() {
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      return 'unknown';
    }
  }
}
