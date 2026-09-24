import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_secondary_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a language whose only versions are root texts is not offered', () {
    const languages = [
      ReaderLanguageOption(
        code: 'bo',
        label: 'Tibetan',
        versionCount: 1,
        translationCount: 0,
      ),
      ReaderLanguageOption(code: 'en', label: 'English', versionCount: 2),
    ];

    expect(translationLanguages(languages).map((l) => l.code), ['en']);
  });

  test('root texts are left out of the versions', () {
    const versions = [
      ReaderVersionDetail(id: 'root', title: 'Root', language: 'bo', isRoot: true),
      ReaderVersionDetail(id: 'tr', title: 'Translation', language: 'bo'),
    ];

    expect(translationVersions(versions).map((v) => v.id), ['tr']);
  });
}
