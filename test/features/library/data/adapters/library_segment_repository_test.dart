import 'package:flutter_pecha/features/library/data/adapters/library_segment_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../library_test_server.dart';

// s1 is a verse of a Tibetan root; r1 is another edition of it, r2/r3 two
// consecutive segments of a commentary on it.
LibraryTestServer _server() => LibraryTestServer({
  '/v2/segments/s1':
      (_) => jsonBody(
        segmentJson(
          's1',
          '1',
          [
            [0, 3],
          ],
          textId: 'root',
          editionId: 'e-root0',
        ),
      ),
  '/v2/segments/s1/related':
      (_) => jsonBody(
        pageJson([
          segmentJson(
            'r1',
            '1',
            [
              [0, 3],
            ],
            textId: 'trans',
            editionId: 'e-root',
          ),
          segmentJson(
            'r3',
            '2',
            [
              [6, 9],
            ],
            textId: 'comm',
            editionId: 'e-comm',
          ),
          segmentJson(
            'r2',
            '1',
            [
              [0, 3],
              [3, 6],
            ],
            textId: 'comm',
            editionId: 'e-comm',
          ),
        ], limit: 20),
      ),
  '/v2/segments/r1':
      (_) => jsonBody(
        segmentJson(
          'r1',
          '1',
          [
            [0, 3],
          ],
          textId: 'root',
          editionId: 'e-root',
        ),
      ),
  '/v2/texts/root': (_) => jsonBody(textJson('root')),
  '/v2/texts/trans': (_) => jsonBody(textJson('trans', translationOf: 'root')),
  '/v2/texts/comm':
      (_) => jsonBody(textJson('comm', commentaryOf: 'root', language: 'en')),
  '/v2/segments/r1/content': (_) => jsonBody('བདག'),
  '/v2/editions/e-root/content': (_) => jsonBody('བདག'),
  '/v2/editions/e-comm/content': (_) => jsonBody('abcdefghi'),
  '/v2/editions/e-root':
      (_) => jsonBody({
        'id': 'e-root',
        'text_id': 'trans',
        'source': 'https://src',
      }),
  '/v2/editions/e-comm': (_) => jsonBody({'id': 'e-comm', 'text_id': 'comm'}),
});

void main() {
  test('one commentary card holds its segments in reading order', () async {
    final response = await LibrarySegmentRepository(
      library: _server().repository(),
    ).getSegmentCommentaries('s1');

    expect(response.parentSegment.segmentId, 's1');
    final commentary = response.commentaries.single;
    expect(commentary.textId, 'comm');
    expect(commentary.title, 'Title comm');
    expect(commentary.language, 'en');
    expect(commentary.license, 'public');
    expect(commentary.source, isNull);
    expect(commentary.count, 2);
    expect(commentary.segments.map((s) => s.segmentId), ['r2', 'r3']);
    expect(commentary.segments.map((s) => s.content), ['abc<br>def', 'ghi']);
    expect(commentary.translations, isEmpty);
  });

  test('translations carry the edition source', () async {
    final response = await LibrarySegmentRepository(
      library: _server().repository(),
    ).getSegmentTranslations('s1');

    final translation = response.translations.single;
    expect(translation.textId, 'trans');
    expect(translation.language, 'bo');
    expect(translation.source, 'https://src');
    expect(translation.segments.single.id, 'r1');
    expect(translation.segments.single.content, 'བདག');
  });

  test('info counts editions; a root has no root text', () async {
    final repository = LibrarySegmentRepository(
      library: _server().repository(),
    );
    final info = await repository.getSegmentInfo('s1');

    expect(info.segmentId, 's1');
    expect(info.translations, 1);
    expect(info.relatedText.commentaries, 1);
    expect(info.relatedText.rootText, 0);
    expect(info.relatedText.hasRootText, isFalse);
    expect(info.videos, isEmpty);
    expect((await repository.getSegmentRootTexts('s1')).translations, isEmpty);
  });

  test('segment detail resolves the text title', () async {
    final detail = await LibrarySegmentRepository(
      library: _server().repository(),
    ).getSegmentWithTextDetails('r1');

    expect(detail.id, 'r1');
    expect(detail.content, 'བདག');
    expect(detail.textTitle, 'Title root');
  });
}
