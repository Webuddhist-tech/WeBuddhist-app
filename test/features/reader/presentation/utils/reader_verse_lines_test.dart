import 'package:flutter_pecha/features/reader/presentation/utils/reader_numerals.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_verse_lines.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_script.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pairLines', () {
    test('pairs line by line when both have as many lines', () {
      final lines = pairLines(
        'om je tsün ma⤵pak ma dröl ma',
        'Om. Homage<br>to the noble lady',
      );
      expect(lines.paired, isTrue);
      expect(lines.original, ['om je tsün ma', 'pak ma dröl ma']);
      expect(lines.translation, ['Om. Homage', 'to the noble lady']);
    });

    test('keeps two blocks when the line counts differ', () {
      final lines = pairLines('a⤵b⤵c', 'one<br/>two');
      expect(lines.paired, isFalse);
      expect(lines.original, ['a<br>b<br>c']);
      expect(lines.translation, ['one<br>two']);
    });

    test('a single line each is a block, not a pair', () {
      final lines = pairLines('a', 'one');
      expect(lines.paired, isFalse);
      expect(lines.original, ['a']);
      expect(lines.translation, ['one']);
    });

    test('blank lines do not count', () {
      final lines = pairLines('a<br><br>b<br> ', 'one<BR>&nbsp;<br>two');
      expect(lines.paired, isTrue);
      expect(lines.original, ['a', 'b']);
      expect(lines.translation, ['one', 'two']);
    });

    test('a line made only of markup is blank', () {
      final lines = pairLines('a<br><span></span><br>b', 'one<br>two');
      expect(lines.paired, isTrue);
    });

    test('one side not shown leaves the other as its block', () {
      expect(pairLines('a⤵b', null).original, ['a<br>b']);
      expect(pairLines('a⤵b', null).translation, isEmpty);
      expect(pairLines(null, 'one<br>two').translation, ['one<br>two']);
      expect(pairLines(null, 'one<br>two').original, isEmpty);
    });

    test('markup inside a line stays with it', () {
      final lines = pairLines(
        'a <span class="yigchung">x</span><br>b',
        'one<br>two',
      );
      expect(lines.original.first, 'a <span class="yigchung">x</span>');
    });
  });

  group('numerals', () {
    test('follow the translation when one is shown, else the original', () {
      expect(
        readerNumeralScript(originalLanguage: 'bo', translationLanguage: 'en'),
        ReaderScript.latin,
      );
      expect(
        readerNumeralScript(originalLanguage: 'en', translationLanguage: 'bo'),
        ReaderScript.tibetan,
      );
      expect(readerNumeralScript(originalLanguage: 'bo'), ReaderScript.tibetan);
      expect(readerNumeralScript(originalLanguage: 'zh'), ReaderScript.chinese);
    });

    test('Tibetan gets Tibetan digits; every other script Western', () {
      expect(readerNumerals('5 / 15', ReaderScript.tibetan), '༥ / ༡༥');
      for (final script in [
        ReaderScript.latin,
        ReaderScript.chinese,
        ReaderScript.devanagari,
        ReaderScript.cyrillic,
      ]) {
        expect(readerNumerals('5 / 15', script), '5 / 15', reason: '$script');
      }
    });

    test('a verse label reads with a dot', () {
      expect(readerVerseLabel('1-12', ReaderScript.latin), '1.12');
      expect(readerVerseLabel('1-12', ReaderScript.tibetan), '༡.༡༢');
      expect(readerVerseLabel('I-3', ReaderScript.latin), 'I.3');
    });

    test('only Tibetan digits fall back on the Tibetan font', () {
      expect(readerNumeralFallback(ReaderScript.tibetan), isNotNull);
      expect(readerNumeralFallback(ReaderScript.latin), isNull);
    });
  });
}
