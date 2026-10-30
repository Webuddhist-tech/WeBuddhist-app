import 'package:flutter_pecha/features/reader/data/models/reader_state.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_actions/reader_verse_sheet.dart';
import 'package:flutter_pecha/features/texts/data/models/segment_info.dart';
import 'package:flutter_test/flutter_test.dart';

SegmentInfo _info({
  int commentaries = 0,
  int translations = 0,
  bool videos = false,
  bool rootText = false,
}) => SegmentInfo(
  segmentId: 'S',
  textId: 'T',
  translations: translations,
  relatedText: SegmentRelatedTextInfo(
    commentaries: commentaries,
    rootText: 0,
    hasRootText: rootText,
  ),
  resources: const SegmentResourcesInfo(sheets: 0),
  videos: [
    if (videos)
      const SegmentVideo(
        id: 'v',
        planId: 'p',
        url: 'https://youtu.be/x',
        videoId: 'x',
        title: 'A talk',
        displayOrder: 0,
      ),
  ],
);

void main() {
  group("a verse sheet's tabs", () {
    test('in order, each only when the verse has something for it', () {
      expect(
        readerResourceTabs(
          _info(commentaries: 2, translations: 1, videos: true, rootText: true),
        ),
        [
          ReaderResourceTab.commentary,
          ReaderResourceTab.versions,
          ReaderResourceTab.videos,
          ReaderResourceTab.rootText,
        ],
      );
      expect(readerResourceTabs(_info(translations: 3)), [
        ReaderResourceTab.versions,
      ]);
      expect(readerResourceTabs(_info()), isEmpty);
    });

    test('none while the counts load; a failed count keeps two', () {
      expect(readerResourceTabs(null), isEmpty);
      expect(readerResourceTabs(null, failed: true), [
        ReaderResourceTab.commentary,
        ReaderResourceTab.versions,
      ]);
    });
  });

  test('copying drops footnote markers and yigchung', () {
    expect(
      readerPlainText('Om<sup>1</sup> mani <i>small</i><b>padme</b>\nhum'),
      'Om mani padme\nhum',
    );
  });
}
