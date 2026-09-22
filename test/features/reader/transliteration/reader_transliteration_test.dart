import 'package:flutter_pecha/features/reader/domain/transliteration/transliteration_service.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_transliteration.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
