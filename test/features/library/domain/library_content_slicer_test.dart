import 'package:flutter_pecha/features/library/data/models/library_segment.dart';
import 'package:flutter_pecha/features/library/domain/library_content_slicer.dart';
import 'package:flutter_test/flutter_test.dart';

LibraryLineSpan _span(int start, int end) =>
    LibraryLineSpan(start: start, end: end);

void main() {
  group('sliceLibraryLines', () {
    test('cuts lines with an exclusive end', () {
      final lines = sliceLibraryLines('abcdef', [_span(0, 3), _span(3, 6)]);
      expect(lines, ['abc', 'def']);
    });

    test('treats offsets as relative to spanStart', () {
      final lines = sliceLibraryLines(
        'abcdef',
        [_span(100, 103), _span(103, 106)],
        spanStart: 100,
      );
      expect(lines, ['abc', 'def']);
    });

    test('counts code points, not UTF-16 units', () {
      final lines = sliceLibraryLines('😀ab', [_span(0, 1), _span(1, 3)]);
      expect(lines, ['😀', 'ab']);
    });

    test('keeps Tibetan lines intact', () {
      const content = 'བདག་གིས་བྱང་ཆུབ་སྤྱོད་པ་ལ། །འཇུག་པ་རྣམ་པར་བརྩམས་པ་ཡི། །';
      final lines = sliceLibraryLines(content, [_span(0, 28), _span(28, 55)]);
      expect(lines, ['བདག་གིས་བྱང་ཆུབ་སྤྱོད་པ་ལ། །', 'འཇུག་པ་རྣམ་པར་བརྩམས་པ་ཡི། །']);
    });

    test('clamps spans that overrun the content', () {
      final lines = sliceLibraryLines('abc', [_span(1, 10), _span(10, 12)]);
      expect(lines, ['bc', '']);
    });

    test('trims surrounding whitespace', () {
      final lines = sliceLibraryLines(' ab \ncd', [_span(0, 4), _span(4, 7)]);
      expect(lines, ['ab', 'cd']);
    });

    test('returns nothing for no lines', () {
      expect(sliceLibraryLines('abc', const []), isEmpty);
    });
  });
}
