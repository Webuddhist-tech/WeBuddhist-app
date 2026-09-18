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
      expect(ids, isNot(contains('br')), reason: 'no phone font');
    });

    test('labels scripts by their own name, Roman included', () {
      expect(converter.scriptById('si')?.label, 'සිංහල');
      expect(converter.scriptById('si')?.roman, isFalse);
      expect(converter.scriptById('ro')?.label, 'Roman');
      expect(converter.scriptById('ro')?.roman, isTrue);
      expect(converter.scriptById('xx'), isNull);
      expect(converter.scriptById(null), isNull);
    });

    test('renders Tibetan output with the Tibetan font', () {
      expect(converter.scriptById('tb')?.fontLanguage, 'bo');
      expect(converter.scriptById('si')?.fontLanguage, isNull);
    });
  });

  group('PaliScriptConverter.polish', () {
    test('restores the Thai letters the package swaps for private-use glyphs', () {
      final thai = converter.convert('ñāṇa', 'th');
      expect(thai, contains('ญ'));
      expect(thai, isNot(matches(RegExp('[\uE000-\uF8FF]'))));
      expect(converter.convert('ṭhāna', 'th'), startsWith('ฐ'));
      expect(PaliScriptConverter.polish('\uF70F\uF700', 'th'), 'ญฐ');
    });

    test('closes Myanmar and Khmer syllables the way those scripts write them', () {
      // "chak" is Tibetan phonetics; Pali itself never ends a word in a consonant.
      expect(PaliScriptConverter.polish('ဆက\u1039 ', 'my'), 'ဆက\u103A ');
      expect(PaliScriptConverter.polish('ဆက\u1039', 'my'), 'ဆက\u103A');
      expect(PaliScriptConverter.polish('ဒ\u1039ဓ', 'my'), 'ဒ\u1039ဓ', reason: 'a real stack');
      expect(PaliScriptConverter.polish('ឆក\u17D2 ', 'km'), 'ឆក ');
      expect(PaliScriptConverter.polish('ទ\u17D2ធ', 'km'), 'ទ\u17D2ធ', reason: 'a real stack');
      expect(PaliScriptConverter.polish('abc', 'hi'), 'abc');
    });
  });
}
