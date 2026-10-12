import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_pecha/core/cache/cache_entry.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Where an error reached the global handlers from.
enum ErrorSource {
  /// `FlutterError.onError`: build, layout, paint, gestures, image streams.
  flutterFramework,

  /// `PlatformDispatcher.onError`: an uncaught error in async code.
  uncaughtAsync,
}

/// What kind of failure an error represents. Drives severity and throttling.
enum ErrorCategory {
  /// The device could not reach a server, or the server failed to answer.
  network,

  /// An image could not be fetched or decoded. The widget shows a fallback.
  imageLoad,

  /// A local file was missing or unreadable, e.g. an evicted cache entry.
  fileSystem,

  /// A Dart [Error]: a bug in app or library code.
  programming,

  /// Anything not recognised above. Treated conservatively.
  unknown;

  /// Environmental failures the app is expected to survive. They are reported
  /// as non-fatal and rate-limited, since they say nothing about code quality.
  bool get isTransient =>
      this == network || this == imageLoad || this == fileSystem;
}

enum ErrorSeverity { fatal, nonFatal }

@immutable
class ErrorClassification {
  final ErrorCategory category;
  final ErrorSeverity severity;

  /// Groups repeats of the same failure for rate limiting, e.g.
  /// `network:SocketException`.
  final String fingerprint;

  const ErrorClassification({
    required this.category,
    required this.severity,
    required this.fingerprint,
  });

  bool get isFatal => severity == ErrorSeverity.fatal;

  @override
  String toString() =>
      'ErrorClassification(${category.name}, ${severity.name}, $fingerprint)';
}

/// Decides how a global error is reported to Crashlytics.
///
/// Every Flutter framework error used to be recorded as a fatal crash. Image
/// download failures and offline errors do not crash the app, yet they
/// dominated the crash-free metric. This classifier separates environmental
/// failures from real defects.
///
/// Errors this class has never seen stay safe by default:
/// * Wrapped errors are unwrapped, so a known cause inside an unknown wrapper
///   is still recognised.
/// * Messages are matched against network signatures, so a new package that
///   throws a plain `Exception('... SocketException ...')` is still network.
/// * Anything still unrecognised keeps the severity its source had before this
///   classifier existed: fatal for framework errors, non-fatal for async ones.
///   A real bug is therefore never silently downgraded.
class ErrorClassifier {
  const ErrorClassifier();

  /// The `library` Flutter stamps on every error raised by an image stream,
  /// whatever the underlying cause: HTTP status, DNS, decode, or memory.
  static const String imageLibrary = 'image resource service';

  /// How deep to follow `inner`/`error` links when unwrapping.
  static const int _maxCauseDepth = 5;

  /// Lower-cased fragments that identify a connectivity failure in an error
  /// message. They catch wrappers this class cannot type-check, such as
  /// `ClientException with SocketException` or a font loader's `Exception`.
  static const List<String> _networkSignatures = [
    'socketexception',
    'failed host lookup',
    'network is unreachable',
    'connection refused',
    'connection reset',
    'connection closed',
    'connection timed out',
    'connection failed',
    'handshakeexception',
    'no internet connection',
    'software caused connection abort',
  ];

  ErrorClassification classifyFlutterError(FlutterErrorDetails details) {
    final category =
        details.library == imageLibrary
            ? ErrorCategory.imageLoad
            : _categorize(details.exception);
    return _classify(
      category: category,
      error: details.exception,
      source: ErrorSource.flutterFramework,
      // Flutter marks errors it considers non-critical as silent.
      silent: details.silent,
    );
  }

  ErrorClassification classifyAsyncError(Object error) {
    return _classify(
      category: _categorize(error),
      error: error,
      source: ErrorSource.uncaughtAsync,
      silent: false,
    );
  }

  ErrorClassification _classify({
    required ErrorCategory category,
    required Object error,
    required ErrorSource source,
    required bool silent,
  }) {
    return ErrorClassification(
      category: category,
      severity: _severity(category, source, silent: silent),
      fingerprint: '${category.name}:${_rootCause(error).runtimeType}',
    );
  }

  ErrorSeverity _severity(
    ErrorCategory category,
    ErrorSource source, {
    required bool silent,
  }) {
    if (category.isTransient || silent) return ErrorSeverity.nonFatal;
    return switch (source) {
      ErrorSource.flutterFramework => ErrorSeverity.fatal,
      ErrorSource.uncaughtAsync => ErrorSeverity.nonFatal,
    };
  }

  ErrorCategory _categorize(Object error) {
    final chain = _causeChain(error);
    for (final cause in chain) {
      final category = _categorizeByType(cause);
      if (category != null) return category;
    }
    for (final cause in chain) {
      if (_looksLikeNetworkFailure(cause)) return ErrorCategory.network;
    }
    return ErrorCategory.unknown;
  }

  ErrorCategory? _categorizeByType(Object error) {
    if (error is SocketException ||
        error is HttpException ||
        error is HandshakeException ||
        error is TlsException ||
        error is TimeoutException ||
        error is http.ClientException ||
        error is NetworkImageLoadException ||
        error is NetworkException ||
        error is OfflineException) {
      return ErrorCategory.network;
    }
    if (error is DioException && _isDioConnectivityFailure(error)) {
      return ErrorCategory.network;
    }
    if (error is FileSystemException) return ErrorCategory.fileSystem;
    if (error is Error) return ErrorCategory.programming;
    return null;
  }

  bool _isDioConnectivityFailure(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return status != null && status >= 500;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        // `unknown` usually wraps the real cause in `error`, which the cause
        // chain inspects next.
        return false;
    }
  }

  bool _looksLikeNetworkFailure(Object error) {
    final String message;
    try {
      message = error.toString().toLowerCase();
    } catch (_) {
      return false;
    }
    return _networkSignatures.any(message.contains);
  }

  /// The error followed by each cause it wraps, outermost first.
  List<Object> _causeChain(Object error) {
    final chain = <Object>[error];
    Object? current = _innerCause(error);
    while (current != null && chain.length <= _maxCauseDepth) {
      if (chain.contains(current)) break;
      chain.add(current);
      current = _innerCause(current);
    }
    return chain;
  }

  Object _rootCause(Object error) => _causeChain(error).last;

  Object? _innerCause(Object error) {
    if (error is WebSocketChannelException) return error.inner;
    if (error is DioException) return error.error;
    if (error is AsyncError) return error.error;
    return null;
  }
}
