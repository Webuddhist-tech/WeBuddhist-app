import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_pecha/core/cache/cache_entry.dart';
import 'package:flutter_pecha/core/error/crash_reporting/error_classifier.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

FlutterErrorDetails _details(
  Object exception, {
  String? library,
  bool silent = false,
}) {
  return FlutterErrorDetails(
    exception: exception,
    library: library,
    silent: silent,
  );
}

DioException _dio(DioExceptionType type, {Object? error, int? statusCode}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: type,
    error: error,
    response:
        statusCode == null
            ? null
            : Response<dynamic>(requestOptions: options, statusCode: statusCode),
  );
}

void main() {
  const classifier = ErrorClassifier();

  group('image errors', () {
    test('any error from the image library is non-fatal imageLoad', () {
      final causes = <Object>[
        const HttpException('Invalid statusCode: 504'),
        NetworkImageLoadException(
          statusCode: 403,
          uri: Uri.parse('https://s3/x.webp'),
        ),
        Exception('Could not allocate intermediate for image decompression.'),
        const PathNotFoundException('/cache/x.jpg', OSError()),
        StateError('a future image codec failure we have never seen'),
      ];
      for (final cause in causes) {
        final result = classifier.classifyFlutterError(
          _details(cause, library: ErrorClassifier.imageLibrary),
        );
        expect(result.category, ErrorCategory.imageLoad, reason: '$cause');
        expect(result.isFatal, isFalse, reason: '$cause');
      }
    });
  });

  group('network errors', () {
    final networkErrors = <String, Object>{
      'SocketException': const SocketException('Failed host lookup'),
      'HttpException': const HttpException('Connection closed'),
      'TimeoutException': TimeoutException('slow'),
      'http.ClientException': http.ClientException('boom'),
      'NetworkException': const NetworkException('No internet connection'),
      'OfflineException': const OfflineException(),
      'WebSocketChannelException wrapping SocketException':
          WebSocketChannelException.from(
            const SocketException("Failed host lookup: 'api.webuddhist.com'"),
          ),
      'Dio connectionError': _dio(DioExceptionType.connectionError),
      'Dio receiveTimeout': _dio(DioExceptionType.receiveTimeout),
      'Dio 503': _dio(DioExceptionType.badResponse, statusCode: 503),
      'Dio unknown wrapping SocketException': _dio(
        DioExceptionType.unknown,
        error: const SocketException('Network is unreachable'),
      ),
      'unseen wrapper type with a network message': Exception(
        'Failed to load font with url https://fonts.gstatic.com/x.ttf: '
        'ClientException with SocketException: Connection failed',
      ),
    };

    networkErrors.forEach((name, error) {
      test('$name is non-fatal network from either source', () {
        final framework = classifier.classifyFlutterError(_details(error));
        final async = classifier.classifyAsyncError(error);
        expect(framework.category, ErrorCategory.network);
        expect(framework.isFatal, isFalse);
        expect(async.category, ErrorCategory.network);
        expect(async.isFatal, isFalse);
      });
    });

    test('a Dio 4xx is not treated as a connectivity failure', () {
      final result = classifier.classifyAsyncError(
        _dio(DioExceptionType.badResponse, statusCode: 404),
      );
      expect(result.category, isNot(ErrorCategory.network));
    });

    test('fingerprint names the innermost cause', () {
      final result = classifier.classifyAsyncError(
        WebSocketChannelException.from(const SocketException('x')),
      );
      expect(result.fingerprint, 'network:SocketException');
    });
  });

  group('file system errors', () {
    test('a missing cache file is non-fatal fileSystem', () {
      final result = classifier.classifyFlutterError(
        _details(const PathNotFoundException('/cache/x.jpg', OSError())),
      );
      expect(result.category, ErrorCategory.fileSystem);
      expect(result.isFatal, isFalse);
    });
  });

  group('defects keep their original severity', () {
    test('a framework programming error stays fatal', () {
      final result = classifier.classifyFlutterError(
        _details(TypeError(), library: 'widgets library'),
      );
      expect(result.category, ErrorCategory.programming);
      expect(result.isFatal, isTrue);
    });

    test('an unrecognised framework error stays fatal', () {
      final result = classifier.classifyFlutterError(
        _details(Exception('Missing required parameters')),
      );
      expect(result.category, ErrorCategory.unknown);
      expect(result.isFatal, isTrue);
    });

    test('an uncaught async programming error stays non-fatal', () {
      final result = classifier.classifyAsyncError(
        StateError('Cannot use "ref" after the widget was disposed.'),
      );
      expect(result.category, ErrorCategory.programming);
      expect(result.isFatal, isFalse);
    });

    test('a framework error Flutter marks silent is non-fatal', () {
      final result = classifier.classifyFlutterError(
        _details(Exception('quiet'), silent: true),
      );
      expect(result.isFatal, isFalse);
    });
  });
}
