import 'package:flutter_pecha/features/reader/domain/transliteration/pali_script_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final converter = PaliScriptConverter();

  group('PaliScriptConverter.detectScript', () {
    test('recognises the two scripts Pali texts arrive in', () {
      expect(converter.detectScript('पदीप पूजा'), 'hi');
      expect(converter.detectScript('Namo tassa bhagavato'), 'ro');
      expect(converter.detectScript('Paṭṭhānapāḷi'), 'ro');
    });

    test('lets neither digits nor punctuation vote', () {
      expect(converter.detectScript('1. साधुकार'), 'hi');
      expect(converter.detectScript('(1) 2. !!!'), isNull);
      expect(converter.detectScript(''), isNull);
    });

    test('picks the majority script of mixed text', () {
      expect(converter.detectScript('अरहं सम्मासम्बुद्धो (a)'), 'hi');
    });
  });

  group('PaliScriptConverter.convert', () {
    test('converts with the source script detected from the text', () {
      expect(converter.convert('buddho', 'si'), 'බුද්ධො');
      expect(converter.convert('බුද්ධො', 'ro'), 'Buddho');
    });

    test('converts Devanagari Pali to Roman with diacritics', () {
      expect(converter.convert('सम्मासम्बुद्धो', 'ro'), 'Sammāsambuddho');
    });

    test('throws on an unknown script id', () {
      expect(() => converter.convert('buddho', 'xx'), throwsArgumentError);
    });
  });

  group('PaliScriptConverter.scripts', () {
    test('offers each script once and skips the unsupported ones', () {
      final ids = converter.scripts.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids, containsAll(['ro', 'hi', 'si', 'tb']));
      expect(ids, isNot(contains('lo')));
      expect(ids, isNot(contains('tt')));
      expect(ids, isNot(contains('as')));
    });

    test('labels scripts by their own name; Roman is the l10n row', () {
      expect(converter.scriptById('si')?.label, 'සිංහල');
      expect(converter.scriptById('si')?.roman, isFalse);
      expect(converter.scriptById('ro')?.label, 'Roman transliteration');
      expect(converter.scriptById('ro')?.roman, isTrue);
      expect(converter.scriptById('xx'), isNull);
      expect(converter.scriptById(null), isNull);
    });

    test('renders Tibetan output with the Tibetan font', () {
      expect(converter.scriptById('tb')?.fontLanguage, 'bo');
      expect(converter.scriptById('si')?.fontLanguage, isNull);
    });
  });
}
