import 'package:flutter_pecha/features/library/data/adapters/library_reader_settings_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../library_test_server.dart';

LibraryTestServer _server() => LibraryTestServer({
  '/v2/editions/E1': (_) => jsonBody({'id': 'E1', 'text_id': 'T1'}),
  '/v2/editions/E3': (_) => jsonBody({'id': 'E3', 'text_id': 'T2'}),
  '/v2/editions/E2':
      (_) => jsonBody({'id': 'E2', 'text_id': 'R', 'source': 'https://src'}),
  '/v2/texts/T1':
      (_) => jsonBody(
        textJson('T1', language: 'en', translationOf: 'R', editions: ['E1']),
      ),
  '/v2/texts/T2':
      (_) => jsonBody(
        textJson('T2', language: 'en', translationOf: 'R', editions: ['E3']),
      ),
  '/v2/texts/T3':
      (_) => jsonBody(textJson('T3', language: 'ne', translationOf: 'R')),
  '/v2/texts/R':
      (_) => jsonBody(
        textJson('R', editions: ['E2'], translations: ['T1', 'T2', 'T3']),
      ),
  '/v2/languages':
      (_) => jsonBody([
        {'code': 'bo', 'name': 'tibetan'},
        {'code': 'en', 'name': 'english'},
      ]),
});

LibraryReaderSettingsRemoteDatasource _datasource(LibraryTestServer server) {
  return LibraryReaderSettingsRemoteDatasource(library: server.repository());
}

void main() {
  test('languages list the text language first, counting editions', () async {
    final response = await _datasource(_server()).fetchLanguages(textId: 'E1');

    expect(response.textId, 'E1');
    expect(response.title, 'Title T1');
    // T3 has no edition, so Nepali is not offered.
    expect(response.availableLanguages.map((l) => l.code), ['en', 'bo']);
    expect(response.availableLanguages.map((l) => l.versionCount), [2, 1]);
    expect(response.availableLanguages.map((l) => l.label), [
      'English',
      'Tibetan',
    ]);
  });

  test('versions are edition ids with the opened edition first', () async {
    final ds = _datasource(_server());

    final fromE1 = await ds.fetchVersions(textId: 'E1', language: 'en');
    expect(fromE1.availableVersions.map((v) => v.id), ['E1', 'E3']);
    expect(fromE1.availableVersions.first.title, 'Title T1');

    final fromE3 = await ds.fetchVersions(textId: 'E3', language: 'en');
    expect(fromE3.availableVersions.map((v) => v.id), ['E3', 'E1']);

    final tibetan = await ds.fetchVersions(textId: 'E1', language: 'bo');
    expect(tibetan.availableVersions.map((v) => v.id), ['E2']);
    expect(tibetan.availableVersions.single.title, 'Title R');
  });

  test('scripts are empty and version info carries the source', () async {
    final ds = _datasource(_server());

    final scripts = await ds.fetchScripts(textId: 'E1', language: 'bo');
    expect(scripts.availableScripts, isEmpty);

    final info = await ds.fetchVersionInfo(versionId: 'E2');
    expect(info.id, 'E2');
    expect(info.language, 'bo');
    expect(info.sourceLink, 'https://src');
  });
}
