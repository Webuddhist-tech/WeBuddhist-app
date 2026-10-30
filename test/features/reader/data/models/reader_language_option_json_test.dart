import 'dart:convert';

import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_test/flutter_test.dart';

/// The screen cache stores the language list as JSON and reads it back.
void main() {
  ReaderLanguageOption roundTrip(ReaderLanguageOption option) =>
      ReaderLanguageOption.fromJson(
        jsonDecode(jsonEncode(option.toJson())) as Map<String, dynamic>,
      );

  test('a root-only language keeps zero translations', () {
    const original = ReaderLanguageOption(
      code: 'bo',
      label: 'Tibetan',
      versionCount: 1,
      translationCount: 0,
    );

    expect(roundTrip(original).translationCount, 0);
  });

  test('a server row without the count falls back to its versions', () {
    final option = ReaderLanguageOption.fromJson({
      'language_code': 'en',
      'language': 'English',
      'version_count': 3,
    });

    expect(option.translationCount, 3);
  });
}
