import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nothing in lib constructs DefaultCacheManager', () {
    final offenders =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where(
              (f) => f.readAsStringSync().contains('DefaultCacheManager('),
            )
            .map((f) => f.path)
            .toList();
    expect(offenders, isEmpty, reason: 'two stores would share one database');
  });
}
