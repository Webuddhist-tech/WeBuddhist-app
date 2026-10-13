import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/error/crash_reporting/crash_reporter.dart';
import 'package:flutter_pecha/core/error/crash_reporting/error_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorded {
  final String kind;
  final Object error;
  final bool fatal;
  final Map<String, String> keys;

  _Recorded(this.kind, this.error, this.fatal, this.keys);
}

void main() {
  late List<_Recorded> recorded;
  late Map<String, String> keys;
  late CrashReporter reporter;

  setUp(() {
    recorded = [];
    keys = {};
    reporter = CrashReporter(
      recordFlutterError: (details, {required fatal}) async {
        recorded.add(
          _Recorded('flutter', details.exception, fatal, Map.of(keys)),
        );
      },
      recordError: (error, stack, {required fatal}) async {
        recorded.add(_Recorded('async', error, fatal, Map.of(keys)));
      },
      setCustomKey: (key, value) async => keys[key] = value,
      maxTransientReportsPerFingerprint: 2,
    );
  });

  // presentError prints to the console; keep test output quiet.
  final originalPresent = FlutterError.presentError;
  setUpAll(() => FlutterError.presentError = (_) {});
  tearDownAll(() => FlutterError.presentError = originalPresent);

  test('image failures are recorded as non-fatal and tagged', () async {
    reporter.handleFlutterError(
      const FlutterErrorDetails(
        exception: HttpException('Invalid statusCode: 504'),
        library: ErrorClassifier.imageLibrary,
      ),
    );
    await reporter.idle;

    expect(recorded, hasLength(1));
    expect(recorded.single.fatal, isFalse);
    expect(recorded.single.keys[CrashReporter.categoryKey], 'imageLoad');
    expect(recorded.single.keys[CrashReporter.sourceKey], 'flutterFramework');
  });

  test('framework defects are still recorded as fatal', () async {
    reporter.handleFlutterError(FlutterErrorDetails(exception: TypeError()));
    await reporter.idle;

    expect(recorded.single.fatal, isTrue);
    expect(recorded.single.keys[CrashReporter.categoryKey], 'programming');
  });

  test('repeated transient failures are throttled per fingerprint', () async {
    for (var i = 0; i < 5; i++) {
      reporter.handleAsyncError(
        const SocketException('Failed host lookup'),
        StackTrace.empty,
      );
    }
    reporter.handleAsyncError(
      const HttpException('Connection closed'),
      StackTrace.empty,
    );
    await reporter.idle;

    final socket = recorded.where((r) => r.error is SocketException);
    final http = recorded.where((r) => r.error is HttpException);
    expect(socket, hasLength(2));
    expect(http, hasLength(1));
  });

  test('defects are never throttled', () async {
    for (var i = 0; i < 5; i++) {
      reporter.handleAsyncError(StateError('bug'), StackTrace.empty);
    }
    await reporter.idle;

    expect(recorded, hasLength(5));
  });

  test('each report carries the keys set for it, not a later one', () async {
    reporter.handleAsyncError(StateError('bug'), StackTrace.empty);
    reporter.handleFlutterError(
      const FlutterErrorDetails(
        exception: SocketException('x'),
        library: ErrorClassifier.imageLibrary,
      ),
    );
    await reporter.idle;

    expect(recorded[0].keys[CrashReporter.categoryKey], 'programming');
    expect(recorded[0].keys[CrashReporter.sourceKey], 'uncaughtAsync');
    expect(recorded[1].keys[CrashReporter.categoryKey], 'imageLoad');
    expect(recorded[1].keys[CrashReporter.sourceKey], 'flutterFramework');
  });

  test('async errors are reported as handled', () {
    expect(
      reporter.handleAsyncError(StateError('bug'), StackTrace.empty),
      isTrue,
    );
  });

  test('a failing Crashlytics call does not break later reports', () async {
    var calls = 0;
    final flaky = CrashReporter(
      recordFlutterError: (_, {required fatal}) async {},
      recordError: (error, stack, {required fatal}) async {
        calls++;
        if (calls == 1) throw StateError('channel down');
      },
      setCustomKey: (_, __) async {},
    );
    flaky.handleAsyncError(StateError('a'), StackTrace.empty);
    flaky.handleAsyncError(StateError('b'), StackTrace.empty);
    await flaky.idle;

    expect(calls, 2);
  });

  // Greptile review on #943: tags are optional and must not block recording.
  test('a failing tag write still records the error', () async {
    final recordedFatal = <bool>[];
    final reporter = CrashReporter(
      recordFlutterError:
          (_, {required fatal}) async => recordedFatal.add(fatal),
      recordError: (_, __, {required fatal}) async {},
      setCustomKey: (_, __) async => throw StateError('channel down'),
    );

    reporter.handleFlutterError(FlutterErrorDetails(exception: TypeError()));
    await reporter.idle;

    expect(recordedFatal, [true]);
  });
}
