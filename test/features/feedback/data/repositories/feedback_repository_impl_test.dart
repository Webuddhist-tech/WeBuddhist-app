import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/feedback/data/datasource/feedback_remote_datasource.dart';
import 'package:flutter_pecha/features/feedback/data/repositories/feedback_repository_impl.dart';
import 'package:flutter_pecha/features/feedback/domain/entities/feedback_report.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDatasource extends FeedbackRemoteDatasource {
  _FakeDatasource([this.error]) : super(dio: Dio());

  final Object? error;
  final sent = <FeedbackReport>[];

  @override
  Future<void> submit(FeedbackReport report) async {
    sent.add(report);
    if (error != null) throw error!;
  }
}

const _report = FeedbackReport(
  message: 'hello',
  imagePaths: [],
  appVersion: '2.5.5 (120)',
  platform: 'ios 17.2',
);

Future<Failure?> _failureFor(Object error) async {
  final result = await FeedbackRepositoryImpl(
    remote: _FakeDatasource(error),
  ).submit(_report);
  return result.getLeft().toNullable();
}

void main() {
  test('passes the report through and succeeds', () async {
    final remote = _FakeDatasource();
    final result = await FeedbackRepositoryImpl(remote: remote).submit(_report);

    expect(result.isRight(), isTrue);
    expect(remote.sent, [_report]);
  });

  test('keeps the too-large code on the failure', () async {
    final failure = await _failureFor(
      const ValidationException(
        'too large',
        code: FeedbackRemoteDatasource.tooLargeCode,
      ),
    );

    expect(failure, isA<ValidationFailure>());
    expect(
      (failure! as ValidationFailure).code,
      FeedbackRemoteDatasource.tooLargeCode,
    );
  });

  test('maps a network error to NetworkFailure', () async {
    expect(
      await _failureFor(const NetworkException('offline')),
      isA<NetworkFailure>(),
    );
  });

  test('unwraps the typed error the error interceptor puts in Dio', () async {
    final options = RequestOptions(path: '/feedback');
    final failure = await _failureFor(
      DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 503),
        type: DioExceptionType.badResponse,
        error: const ServerException('Server error (503)'),
      ),
    );

    expect(failure, isA<ServerFailure>());
  });
}
