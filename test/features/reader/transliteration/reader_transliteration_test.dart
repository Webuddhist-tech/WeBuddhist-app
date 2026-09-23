import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/flattened_item.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/tibetan_script_converter.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/transliteration_service.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_transliteration.dart';
import 'package:flutter_pecha/features/texts/data/models/section.dart';
import 'package:flutter_pecha/features/texts/data/models/segment.dart';
import 'package:flutter_test/flutter_test.dart';

FlattenedContent _content(List<String?> contents) => FlattenedContent(
  items: [
    FlattenedItem.header(
      section: const Section(id: 's', title: 'Derge Kangyur', sectionNumber: 1, segments: []),
      depth: 0,
    ),
    for (var i = 0; i < contents.length; i++)
      FlattenedItem.segment(
        segment: Segment(
          segmentId: 'seg$i',
          segmentNumber: i,
          content: contents[i],
        ),
        depth: 1,
        sectionId: 's',
      ),
  ],
  segmentIndexMap: const {},
  totalSegments: contents.length,
);

void main() {
  final service = TransliterationService.standard();

  group('transliterateSegmentHtml', () {
    test('leaves the html alone when no script is picked', () {
      expect(
        transliterateSegmentHtml(
          service,
          html: 'བོད་སྐྱོང<br>ལྷ་སྲུང',
          language: 'bo',
          scriptId: null,
        ),
        'བོད་སྐྱོང<br>ལྷ་སྲུང',
      );
    });

    test('converts the text and keeps the markup, so copy matches the screen', () {
      expect(
        transliterateSegmentHtml(
          service,
          html: 'བོད་སྐྱོང<br>ལྷ་སྲུང',
          language: 'bo',
          scriptId: 'phonetic',
        ),
        'bö kyong<br>lha sung',
      );
      // A shad becomes a line break in the default mark style, as <br>.
      expect(
        transliterateSegmentHtml(
          service,
          html: 'རྒྱ་གར། ན་མོ།',
          language: 'bo',
          scriptId: 'phonetic',
        ),
        'gya gar<br>na mo',
      );
    });

    test('falls back to the original for a language without a converter', () {
      expect(
        transliterateSegmentHtml(
          service,
          html: 'Homage',
          language: 'en',
          scriptId: 'phonetic',
        ),
        'Homage',
      );
    });
  });

  group('scriptDetectionSample', () {
    final tibetan = TibetanScriptConverter();

    test('samples the verses, never the title', () {
      // The section header reads "Derge Kangyur": romanised, as catalogue
      // titles are, while the verses are Uchen. Detecting from the title
      // called the text Roman and hid the Roman row - the one worth having.
      final sample = scriptDetectionSample(
        _content(['<p>བཀྲ་ཤིས་བདེ་ལེགས།</p>', 'ཨོཾ་མ་ཎི།']),
      );
      expect(tibetan.detectScript(sample), 'tibetan');
      expect(sample, isNot(contains('Derge')));
    });

    test('strips markup so tag names cannot vote', () {
      expect(
        scriptDetectionSample(_content(['<p class="verse">བཀྲ་ཤིས།</p>&amp;'])),
        isNot(contains('p')),
      );
    });

    test('skips empty segments and stops once it has enough', () {
      final sample = scriptDetectionSample(
        _content([null, '', ...List.filled(200, 'བཀྲ་ཤིས་བདེ་ལེགས། ')]),
      );
      expect(sample, isNotEmpty);
      expect(sample.length, lessThan(600));
    });

    test('is empty when nothing is loaded', () {
      expect(scriptDetectionSample(null), '');
      expect(scriptDetectionSample(_content(const [])), '');
      expect(tibetan.detectScript(scriptDetectionSample(null)), isNull);
    });
  });
}

