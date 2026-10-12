import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/error/crash_reporting/error_classifier.dart';
import 'package:flutter_pecha/core/utils/network_image_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Greptile review on #943: handled image failures must still be reported,
  // as non-fatals, rather than dropped.
  test('reportImageLoadError forwards the failure as a non-fatal image '
      'error', () {
    final reported = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = original);

    const error = HttpException('Invalid statusCode: 403');
    reportImageLoadError(error, StackTrace.current);

    expect(reported, hasLength(1));
    final details = reported.single;
    expect(details.exception, error);
    expect(details.library, ErrorClassifier.imageLibrary);

    final classification = const ErrorClassifier().classifyFlutterError(
      details,
    );
    expect(classification.category, ErrorCategory.imageLoad);
    expect(classification.isFatal, isFalse);
  });
}
