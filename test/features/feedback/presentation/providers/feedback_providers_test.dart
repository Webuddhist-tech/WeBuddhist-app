import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/feedback/data/datasource/feedback_remote_datasource.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/feedback_report.dart';
import 'package:flutter_pecha/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:flutter_pecha/features/feedback/presentation/providers/feedback_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _FakeRepository implements FeedbackRepository {
  _FakeRepository([this.failure]);

  final Failure? failure;
  final sent = <FeedbackReport>[];

  @override
  Future<Either<Failure, void>> submit(FeedbackReport report) async {
    sent.add(report);
    final failure = this.failure;
    return failure == null ? const Right(null) : Left(failure);
  }
}

ProviderContainer _container(_FakeRepository repository) {
  final container = ProviderContainer(
    overrides: [
      feedbackRepositoryProvider.overrideWithValue(repository),
      packageInfoProvider.overrideWith(
        (ref) async => PackageInfo(
          appName: 'WeBuddhist',
          packageName: 'org.pecha.app',
          version: '2.5.5',
          buildNumber: '120',
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('feedbackFailureOf', () {
    test('picks the message the sheet shows for each failure', () {
      expect(
        feedbackFailureOf(const NetworkFailure('offline')),
        FeedbackFailure.offline,
      );
      expect(
        feedbackFailureOf(const RateLimitFailure('slow down')),
        FeedbackFailure.rateLimited,
      );
      expect(
        feedbackFailureOf(
          const ValidationFailure(
            'too large',
            code: FeedbackRemoteDatasource.tooLargeCode,
          ),
        ),
        FeedbackFailure.tooLarge,
      );
      expect(
        feedbackFailureOf(const NotFoundFailure('no endpoint')),
        FeedbackFailure.unavailable,
      );
      expect(
        feedbackFailureOf(const ServerFailure('Server error (503)')),
        FeedbackFailure.unavailable,
      );
    });

    test('any other 400 and auth failures get the generic message', () {
      expect(
        feedbackFailureOf(const ValidationFailure('not a valid image')),
        FeedbackFailure.failed,
      );
      expect(
        feedbackFailureOf(const AuthenticationFailure('Unauthorized')),
        FeedbackFailure.failed,
      );
      expect(
        feedbackFailureOf(const AuthorizationFailure('Forbidden')),
        FeedbackFailure.failed,
      );
      expect(
        feedbackFailureOf(const UnknownFailure('?')),
        FeedbackFailure.failed,
      );
    });
  });

  group('SendFeedback', () {
    test('sends the message with app and device context', () async {
      final repository = _FakeRepository();
      final container = _container(repository);

      await container.read(sendFeedbackProvider)(
        message: 'hello',
        imagePaths: ['/tmp/a.jpg'],
      );

      final report = repository.sent.single;
      expect(report.message, 'hello');
      expect(report.imagePaths, ['/tmp/a.jpg']);
      expect(report.appVersion, '2.5.5 (120)');
      expect(report.platform, isNotEmpty);
    });

    test('throws the mapped FeedbackException on failure', () async {
      final container = _container(
        _FakeRepository(const NetworkFailure('offline')),
      );

      await expectLater(
        container.read(sendFeedbackProvider)(message: 'hello'),
        throwsA(
          isA<FeedbackException>().having(
            (e) => e.failure,
            'failure',
            FeedbackFailure.offline,
          ),
        ),
      );
    });
  });
}
