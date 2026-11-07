import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/error/load_error_kind.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dio({
  DioExceptionType type = DioExceptionType.badResponse,
  int? status,
  Object? error,
}) {
  final request = RequestOptions(path: '/v2/editions/E/content');
  return DioException(
    requestOptions: request,
    type: type,
    error: error,
    response:
        status == null
            ? null
            : Response(requestOptions: request, statusCode: status),
  );
}

void main() {
  group('no connection', () {
    test('as the error interceptor passes it on', () {
      expect(
        loadErrorKindOf(
          _dio(
            type: DioExceptionType.connectionError,
            error: const NetworkException('No internet connection'),
          ),
        ),
        LoadErrorKind.connection,
      );
    });

    test('a bare Dio connection error or timeout', () {
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(loadErrorKindOf(_dio(type: type)), LoadErrorKind.connection);
      }
    });

    test('a socket, a timeout, or a network failure', () {
      expect(
        loadErrorKindOf(const SocketException('Failed host lookup')),
        LoadErrorKind.connection,
      );
      expect(loadErrorKindOf(TimeoutException('slow')), LoadErrorKind.connection);
      expect(
        loadErrorKindOf(const NetworkFailure('offline')),
        LoadErrorKind.connection,
      );
    });
  });

  group('the server or the setup', () {
    test('a 422 the library answers with (content-state migration)', () {
      expect(
        loadErrorKindOf(
          _dio(
            status: 422,
            error: const ValidationException('requires the migration'),
          ),
        ),
        LoadErrorKind.server,
      );
      expect(loadErrorKindOf(_dio(status: 422)), LoadErrorKind.server);
    });

    test('a 5xx', () {
      expect(
        loadErrorKindOf(_dio(status: 503, error: const ServerException('down'))),
        LoadErrorKind.server,
      );
    });

    test('a setting the app is missing', () {
      expect(
        loadErrorKindOf(StateError('LIBRARY_CHANTS_TAG_ID is not configured')),
        LoadErrorKind.server,
      );
      expect(
        loadErrorKindOf(const UnknownFailure('Failed to load chants')),
        LoadErrorKind.server,
      );
    });
  });

  group('nothing there', () {
    test('a 404', () {
      expect(
        loadErrorKindOf(
          _dio(status: 404, error: const NotFoundException('no such text')),
        ),
        LoadErrorKind.missing,
      );
      expect(loadErrorKindOf(_dio(status: 404)), LoadErrorKind.missing);
      expect(
        loadErrorKindOf(const NotFoundFailure('no such text')),
        LoadErrorKind.missing,
      );
    });
  });
}
