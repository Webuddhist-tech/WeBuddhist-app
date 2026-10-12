import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/error/crash_reporting/error_classifier.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

typedef RecordFlutterError =
    Future<void> Function(FlutterErrorDetails details, {required bool fatal});
typedef RecordError =
    Future<void> Function(
      Object error,
      StackTrace? stack, {
      required bool fatal,
    });
typedef SetCustomKey = Future<void> Function(String key, String value);

/// Routes every globally unhandled error through [ErrorClassifier] before it
/// reaches Crashlytics.
///
/// * Severity comes from the classifier, so offline and image failures no
///   longer count as crashes.
/// * Each report carries `error_category` and `error_source` custom keys, so
///   new kinds of failure can be triaged in the console without a release.
/// * A transient failure is reported at most [maxTransientReportsPerFingerprint]
///   times per app run. Impacted-user counts stay accurate, but one offline
///   user can no longer generate hundreds of events.
class CrashReporter {
  CrashReporter({
    required RecordFlutterError recordFlutterError,
    required RecordError recordError,
    required SetCustomKey setCustomKey,
    this.classifier = const ErrorClassifier(),
    this.maxTransientReportsPerFingerprint = 3,
  }) : _recordFlutterError = recordFlutterError,
       _recordError = recordError,
       _setCustomKey = setCustomKey;

  factory CrashReporter.forCrashlytics(FirebaseCrashlytics crashlytics) {
    return CrashReporter(
      recordFlutterError:
          (details, {required fatal}) =>
              crashlytics.recordFlutterError(details, fatal: fatal),
      recordError:
          (error, stack, {required fatal}) =>
              crashlytics.recordError(error, stack, fatal: fatal),
      setCustomKey: crashlytics.setCustomKey,
    );
  }

  static const String categoryKey = 'error_category';
  static const String sourceKey = 'error_source';

  static final _logger = AppLogger('CrashReporter');

  final RecordFlutterError _recordFlutterError;
  final RecordError _recordError;
  final SetCustomKey _setCustomKey;
  final ErrorClassifier classifier;
  final int maxTransientReportsPerFingerprint;

  final Map<String, int> _transientReportCounts = {};

  /// Crashlytics custom keys are session-wide, not per event. Running each
  /// report to completion before the next one starts keeps the keys set for
  /// an event from being overwritten by a concurrent one.
  Future<void> _pending = Future<void>.value();

  /// Installs this reporter as the app-wide Flutter and async error handler.
  void install() {
    FlutterError.onError = handleFlutterError;
    WidgetsBinding.instance.platformDispatcher.onError = handleAsyncError;
  }

  void handleFlutterError(FlutterErrorDetails details) {
    final classification = classifier.classifyFlutterError(details);
    if (!_shouldReport(classification)) {
      // Still show it in the debug console; only the upload is skipped.
      FlutterError.presentError(details);
      return;
    }
    _enqueue(
      classification,
      ErrorSource.flutterFramework,
      () => _recordFlutterError(details, fatal: classification.isFatal),
    );
  }

  /// Returns true so the engine treats the error as handled.
  bool handleAsyncError(Object error, StackTrace stack) {
    final classification = classifier.classifyAsyncError(error);
    _logger.error('Uncaught async error ($classification)', error, stack);
    if (_shouldReport(classification)) {
      _enqueue(
        classification,
        ErrorSource.uncaughtAsync,
        () => _recordError(error, stack, fatal: classification.isFatal),
      );
    }
    return true;
  }

  bool _shouldReport(ErrorClassification classification) {
    if (!classification.category.isTransient) return true;
    final count = _transientReportCounts.update(
      classification.fingerprint,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    return count <= maxTransientReportsPerFingerprint;
  }

  void _enqueue(
    ErrorClassification classification,
    ErrorSource source,
    Future<void> Function() record,
  ) {
    _pending = _pending.then((_) async {
      try {
        await _setCustomKey(categoryKey, classification.category.name);
        await _setCustomKey(sourceKey, source.name);
        await record();
      } catch (e) {
        // Never let a reporting failure re-enter the global error handlers.
        _logger.warning('Failed to report error to Crashlytics: $e');
      }
    });
  }

  /// Completes once every report queued so far has been sent. For tests.
  @visibleForTesting
  Future<void> get idle => _pending;
}
