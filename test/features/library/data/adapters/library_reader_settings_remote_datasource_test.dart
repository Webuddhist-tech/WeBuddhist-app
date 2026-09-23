import 'package:flutter_pecha/features/library/data/adapters/library_reader_settings_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../library_test_server.dart';

LibraryTestServer _server() => LibraryTestServer({
  '/v2/texts/T1':
      (_) => jsonBody(textJson('T1', language: 'en', translationOf: 'R')),
  '/v2/texts/T2':
      (_) => jsonBody(textJson('T2', language: 'en', translationOf: 'R')),
  '/v2/texts/R':
      (_) => jsonBody(
        textJson('R', editions: ['E2'], translations: ['T1', 'T2']),
      ),
  '/v2/editions/E2':
      (_) => jsonBody({'id': 'E2', 'text_id': 'R', 'source': 'https://src'}),
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
  test('languages list the text language first with version counts', () async {
    final response = await _datasource(_server()).fetchLanguages(textId: 'T1');

    expect(response.textId, 'T1');
    expect(response.title, 'Title T1');
    expect(response.availableLanguages.map((l) => l.code), ['en', 'bo']);
    expect(response.availableLanguages.map((l) => l.versionCount), [2, 1]);
    expect(response.availableLanguages.map((l) => l.label), [
      'English',
      'Tibetan',
    ]);
  });

  test('versions of a language put the requested text first', () async {
    final ds = _datasource(_server());

    final fromT1 = await ds.fetchVersions(textId: 'T1', language: 'en');
    expect(fromT1.availableVersions.map((v) => v.id), ['T1', 'T2']);

    final fromT2 = await ds.fetchVersions(textId: 'T2', language: 'en');
    expect(fromT2.availableVersions.map((v) => v.id), ['T2', 'T1']);

    final tibetan = await ds.fetchVersions(textId: 'T1', language: 'bo');
    expect(tibetan.availableVersions.map((v) => v.id), ['R']);
    expect(tibetan.availableVersions.single.title, 'Title R');
  });

  test('scripts are empty and version info carries the source', () async {
    final ds = _datasource(_server());

    final scripts = await ds.fetchScripts(textId: 'T1', language: 'bo');
    expect(scripts.availableScripts, isEmpty);

    final info = await ds.fetchVersionInfo(versionId: 'R');
    expect(info.id, 'R');
    expect(info.language, 'bo');
    expect(info.sourceLink, 'https://src');
  });
}
