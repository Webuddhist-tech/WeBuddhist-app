import 'package:flutter_pecha/features/reader/presentation/widgets/reader_content/reader_scroll_chrome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('focus mode', () {
    test('bars stay until the page has moved 24 px down', () {
      final mode = ReaderFocusMode();
      expect(mode.scrolled(10), isFalse);
      expect(mode.scrolled(13), isFalse);
      expect(mode.barsVisible, isTrue);
      expect(mode.scrolled(1), isTrue);
      expect(mode.barsVisible, isFalse);
    });

    test('8 px up brings them back', () {
      final mode = ReaderFocusMode()..scrolled(30);
      expect(mode.scrolled(-7), isFalse);
      expect(mode.barsVisible, isFalse);
      expect(mode.scrolled(-1), isTrue);
      expect(mode.barsVisible, isTrue);
    });

    test('each direction counts from where the page last turned', () {
      final mode = ReaderFocusMode();
      mode.scrolled(20);
      mode.scrolled(-2);
      // The 20 px before the turn no longer count.
      expect(mode.scrolled(20), isFalse);
      expect(mode.barsVisible, isTrue);
      expect(mode.scrolled(4), isTrue);
    });

    test('a step up the app makes does not bring the bars back', () {
      final mode = ReaderFocusMode()..scrolled(40);
      expect(mode.scrolled(-400, countUp: false), isFalse);
      expect(mode.barsVisible, isFalse);
    });

    test('a step down the app makes still hides them', () {
      final mode = ReaderFocusMode();
      expect(mode.scrolled(30, countUp: false), isTrue);
      expect(mode.barsVisible, isFalse);
    });

    test('nothing changes while the bars are already where they go', () {
      final mode = ReaderFocusMode();
      expect(mode.scrolled(-50), isFalse);
      mode.scrolled(30);
      expect(mode.scrolled(100), isFalse);
      expect(mode.barsVisible, isFalse);
    });

    test('show brings hidden bars back and starts counting afresh', () {
      final mode = ReaderFocusMode()..scrolled(30);
      expect(mode.show(), isTrue);
      expect(mode.barsVisible, isTrue);
      expect(mode.show(), isFalse);
      // The steps before show do not carry over.
      expect(mode.scrolled(20), isFalse);
      expect(mode.scrolled(4), isTrue);
    });
  });

  group('reading progress', () {
    test('a whole text is measured by its verses', () {
      expect(
        readerProgress(
          lastVerseNumber: 25,
          totalVerses: 100,
          lastVisibleRow: 3,
          rowCount: 30,
        ),
        0.25,
      );
    });

    test('a plan task is measured by its rows', () {
      expect(readerProgress(lastVisibleRow: 9, rowCount: 20), 0.5);
    });

    test('stays between 0 and 1', () {
      expect(
        readerProgress(
          lastVerseNumber: 120,
          totalVerses: 100,
          lastVisibleRow: 0,
          rowCount: 1,
        ),
        1,
      );
      expect(readerProgress(lastVisibleRow: 0, rowCount: 0), 0);
    });
  });

  group('plan task progress', () {
    test('counts the task\'s verses, not the rows loaded so far', () {
      // Twenty picked verses, the first ten loaded and the last of them on
      // screen: half way, not the end.
      expect(
        readerTaskProgress(sourceVerses: [20], source: 0, verseInSource: 10),
        0.5,
      );
    });

    test('earlier texts count in full', () {
      expect(
        readerTaskProgress(
          sourceVerses: [10, 10],
          source: 1,
          verseInSource: 5,
        ),
        0.75,
      );
    });

    test('a text not started yet keeps the line short of the end', () {
      final value = readerTaskProgress(
        sourceVerses: [10, null],
        source: 0,
        verseInSource: 10,
      );
      expect(value, lessThan(1));
      expect(value, closeTo(10 / 11, 1e-9));
    });

    test('reaches the end on the task\'s last verse', () {
      expect(
        readerTaskProgress(
          sourceVerses: [5, 30],
          source: 1,
          verseInSource: 30,
        ),
        1,
      );
    });
  });
}
