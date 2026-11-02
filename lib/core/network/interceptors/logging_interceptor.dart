import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

/// Interceptor that logs all HTTP requests and responses.
///
/// Provides detailed logging for debugging API calls in development mode.
/// Includes request IDs and durations for log correlation.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor(this._logger);

  final AppLogger _logger;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final requestId = options.extra['requestId'] ?? 'unknown';
    _logger.info('[$requestId] API Request: ${options.method} ${options.path}');
    _logger.debug('[$requestId] Headers: ${_filterHeaders(options.headers)}');
    if (options.data != null && options.data is! Map) {
      _logger.debug('[$requestId] Body: ${options.data}');
    } else if (options.queryParameters.isNotEmpty) {
      _logger.debug('[$requestId] Query: ${options.queryParameters}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final requestId = response.requestOptions.extra['requestId'] ?? 'unknown';
    final startTime = response.requestOptions.extra['requestStartTime'] as DateTime?;
    final durationStr = startTime != null
        ? ' (${DateTime.now().difference(startTime).inMilliseconds}ms)'
        : '';
    _logger.info(
      '[$requestId] API Response: ${response.statusCode} '
      '${response.requestOptions.path}$durationStr',
    );
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final requestId = err.requestOptions.extra['requestId'] ?? 'unknown';
    _logger.error(
      '[$requestId] API Error: ${err.requestOptions.method} ${err.requestOptions.path} '
      '- ${err.response?.statusCode ?? err.type}',
      err.error,
      err.stackTrace,
    );
    handler.next(err);
  }

  /// Filter sensitive headers from logs
  Map<String, dynamic> _filterHeaders(Map<String, dynamic> headers) {
    final filtered = <String, dynamic>{};
    for (final entry in headers.entries) {
      final key = entry.key.toLowerCase();
      if (key == 'authorization') {
        filtered[entry.key] = 'Bearer ***';
      } else if (key == 'x-api-key') {
        filtered[entry.key] = '***';
      } else {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered;
  }
}
