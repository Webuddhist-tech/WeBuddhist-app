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
  test('languages list the root language first, counting editions', () async {
    final response = await _datasource(_server()).fetchLanguages(textId: 'E1');

    expect(response.textId, 'E1');
    expect(response.title, 'Title T1');
    // T3 has no edition, so Nepali is not offered.
    expect(response.availableLanguages.map((l) => l.code), ['bo', 'en']);
    expect(response.availableLanguages.map((l) => l.versionCount), [1, 2]);
    expect(response.availableLanguages.map((l) => l.label), [
      'Tibetan',
      'English',
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

  test("a translation of a translation names the edition it was made from",
      () async {
    final server = LibraryTestServer({
      '/v2/editions/E-sa': (_) => jsonBody({'id': 'E-sa', 'text_id': 'SA'}),
      '/v2/editions/E-bo': (_) => jsonBody({'id': 'E-bo', 'text_id': 'BO'}),
      '/v2/editions/E-en': (_) => jsonBody({'id': 'E-en', 'text_id': 'EN'}),
      '/v2/texts/SA':
          (_) => jsonBody(
            textJson('SA', language: 'sa', editions: ['E-sa'], translations: ['BO']),
          ),
      '/v2/texts/BO':
          (_) => jsonBody(
            textJson('BO', translationOf: 'SA', editions: ['E-bo'], translations: ['EN']),
          ),
      '/v2/texts/EN':
          (_) => jsonBody(
            textJson('EN', language: 'en', translationOf: 'BO', editions: ['E-en']),
          ),
    });
    final ds = _datasource(server);

    expect((await ds.fetchVersionInfo(versionId: 'E-en')).parentId, 'E-bo');
    expect((await ds.fetchVersionInfo(versionId: 'E-bo')).parentId, 'E-sa');

    final english = await ds.fetchVersions(textId: 'E-en', language: 'en');
    expect(english.availableVersions.single.parentId, 'E-bo');

    final languages = await ds.fetchLanguages(textId: 'E-en');
    expect(languages.availableLanguages.map((l) => l.code), ['bo', 'en', 'sa']);
    // The Sanskrit root is only ever an original; the Tibetan is a translation.
    expect(
      languages.availableLanguages.map((l) => l.translationCount),
      [1, 1, 0],
    );
    final sanskrit = await ds.fetchVersions(textId: 'E-en', language: 'sa');
    expect(sanskrit.availableVersions.single.isRoot, isTrue);
    final tibetan = await ds.fetchVersions(textId: 'E-en', language: 'bo');
    expect(tibetan.availableVersions.single.isRoot, isFalse);
  });

  test('a translation names the root edition as its parent', () async {
    final ds = _datasource(_server());

    final translation = await ds.fetchVersionInfo(versionId: 'E1');
    expect(translation.parentId, 'E2', reason: 'an edition id, not a text id');
    expect(translation.title, 'Title T1');

    final root = await ds.fetchVersionInfo(versionId: 'E2');
    expect(root.parentId, isNull);

    final versions = await ds.fetchVersions(textId: 'E2', language: 'en');
    expect(versions.availableVersions.map((v) => v.parentId), ['E2', 'E2']);
  });

  group('a translation covering little of the original', () {
    // The root (E-root) has three verses. English is aligned to all of
    // them, Mongolian to the first only (a homage line), Chinese has no
    // alignment but numbers all three, Hindi numbers only the first.
    LibraryTestServer coverageServer() => LibraryTestServer({
      '/v2/editions/E-root': (_) => jsonBody({'id': 'E-root', 'text_id': 'R'}),
      '/v2/texts/R':
          (_) => jsonBody(
            textJson(
              'R',
              editions: ['E-root'],
              translations: ['EN', 'MN', 'ZH', 'HI'],
            ),
          ),
      '/v2/texts/EN':
          (_) => jsonBody(
            textJson('EN', language: 'en', translationOf: 'R', editions: ['E-en']),
          ),
      '/v2/texts/MN':
          (_) => jsonBody(
            textJson('MN', language: 'mn', translationOf: 'R', editions: ['E-mn']),
          ),
      '/v2/texts/ZH':
          (_) => jsonBody(
            textJson('ZH', language: 'zh', translationOf: 'R', editions: ['E-zh']),
          ),
      '/v2/texts/HI':
          (_) => jsonBody(
            textJson('HI', language: 'hi', translationOf: 'R', editions: ['E-hi']),
          ),
      '/v2/editions/E-root/segmentation/segments':
          (_) => jsonBody(pageJson(threeVerses('r'))),
      '/v2/editions/E-zh/segmentation/segments':
          (_) => jsonBody(pageJson(threeVerses('z'))),
      '/v2/editions/E-hi/segmentation/segments':
          (_) => jsonBody(
            pageJson([
              segmentJson('h1', '1', [
                [0, 3],
              ]),
            ]),
          ),
      '/v2/editions/E-root/alignments/E-en':
          (_) => jsonBody(
            pageJson([
              alignmentJson('r1', 'e1'),
              alignmentJson('r2', 'e2'),
              alignmentJson('r3', 'e3'),
            ]),
          ),
      '/v2/editions/E-root/alignments/E-mn':
          (_) => jsonBody(pageJson([alignmentJson('r1', 'm1')])),
      '/v2/editions/E-root/alignments/E-zh': (_) => jsonBody(pageJson([])),
      '/v2/editions/E-zh/alignments/E-root': (_) => jsonBody(pageJson([])),
      '/v2/editions/E-root/alignments/E-hi': (_) => jsonBody(pageJson([])),
      '/v2/editions/E-hi/alignments/E-root': (_) => jsonBody(pageJson([])),
    });

    test('is not counted as a translation language', () async {
      final languages = await _datasource(
        coverageServer(),
      ).fetchLanguages(textId: 'E-root');
      final counts = {
        for (final l in languages.availableLanguages) l.code: l.translationCount,
      };
      // By the alignment: English all, Mongolian one verse of three. By
      // verse number: Chinese all, Hindi one.
      expect(counts, {'bo': 0, 'en': 1, 'hi': 0, 'mn': 0, 'zh': 1});
    });

    test('is not offered as a version, so the reader never opens it', () async {
      final ds = _datasource(coverageServer());
      expect(
        (await ds.fetchVersions(textId: 'E-root', language: 'mn'))
            .availableVersions,
        isEmpty,
      );
      expect(
        (await ds.fetchVersions(
          textId: 'E-root',
          language: 'en',
        )).availableVersions.map((v) => v.id),
        ['E-en'],
      );
    });

    test('opened on its own, it is still its own first version', () async {
      final server = coverageServer();
      server.routes['/v2/editions/E-mn'] =
          (_) => jsonBody({'id': 'E-mn', 'text_id': 'MN'});
      final versions = await _datasource(
        server,
      ).fetchVersions(textId: 'E-mn', language: 'mn');
      expect(versions.availableVersions.map((v) => v.id), ['E-mn']);
    });

    test('a language stops at its first edition that covers', () async {
      final server = coverageServer();
      server.routes['/v2/texts/EN'] =
          (_) => jsonBody(
            textJson(
              'EN',
              language: 'en',
              translationOf: 'R',
              editions: ['E-en', 'E-en2'],
            ),
          );
      final languages = await _datasource(
        server,
      ).fetchLanguages(textId: 'E-root');

      expect(
        languages.availableLanguages
            .firstWhere((l) => l.code == 'en')
            .translationCount,
        greaterThan(0),
      );
      expect(server.count('/v2/editions/E-root/alignments/E-en2'), 0);
    });

    test('is measured once, and keeps the text being read in memory', () async {
      final server = coverageServer();
      // Room for one edition's verses: the one being read.
      final library = server.repository(segmentCacheSize: 1);
      await library.getEditionSegments('E-root');
      final ds = LibraryReaderSettingsRemoteDatasource(library: library);

      await ds.fetchLanguages(textId: 'E-root');
      await ds.fetchLanguages(textId: 'E-root');
      await library.getEditionSegments('E-root');

      const root = '/v2/editions/E-root/segmentation/segments';
      const chinese = '/v2/editions/E-zh/segmentation/segments';
      expect(server.count(root), 1, reason: 'never pushed out of the cache');
      expect(server.count(chinese), 1, reason: 'measured once a session');
    });

    test('one that cannot be measured is offered, not hidden', () async {
      final server = coverageServer()
        ..routes.remove('/v2/editions/E-root/alignments/E-mn');
      server.routes.remove('/v2/editions/E-root/segmentation/segments');
      final languages = await _datasource(
        server,
      ).fetchLanguages(textId: 'E-root');
      expect(
        languages.availableLanguages
            .firstWhere((l) => l.code == 'mn')
            .translationCount,
        1,
      );
    });
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
