import 'package:flutter_pecha/features/reader/domain/transliteration/tibetan_script_converter.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/transliteration_service.dart';
import 'package:flutter_test/flutter_test.dart';

final _tibetan = RegExp(r'[ༀ-࿿]');
final _latinLetters = RegExp('[A-Za-z]');
final _devanagari = RegExp(r'[ऀ-ॿ]');
final _sinhala = RegExp(r'[඀-෿]');

void main() {
  final converter = TibetanScriptConverter();

  test('handles Tibetan and names the text as written', () {
    expect(converter.languageCode, 'bo');
    expect(converter.detectScript('བོད་སྐྱོང་ལྷ་སྲུང་གི་འཕྲིན་བསྐུལ།'), 'tibetan');
    expect(converter.detectScript('༡༩ ། །'), isNull);
    expect(converter.scriptById('tibetan')?.label, 'བོད་ཡིག');
    expect(converter.scriptById('tibetan')?.roman, isFalse);
  });

  test('converts to phonetics, leaves Tibetan as is, rejects unknown ids', () {
    expect(converter.convert('བོད', 'phonetic'), 'bö');
    expect(converter.convert('བོད', 'tibetan'), 'བོད');
    expect(() => converter.convert('བོད', 'xx'), throwsArgumentError);
    expect(() => converter.convert('བོད', 'wylie'), throwsArgumentError);
    expect(() => converter.convert('བོད', 'phonetic:xx'), throwsArgumentError);
  });

  test('one Roman row, called Roman, in the Latin font', () {
    final ids = converter.scripts.map((s) => s.id).toList();
    expect(ids.take(2), ['tibetan', 'phonetic']);
    expect(ids, isNot(contains('wylie')));
    final roman = converter.scriptById('phonetic')!;
    expect(roman.roman, isTrue);
    expect(roman.label, 'Roman');
    expect(roman.fontLanguage, 'en');
    expect(converter.scriptById('tibetan')?.fontLanguage, isNull);
  });

  group('scripts reached through the phonetics', () {
    test('offers every Pali script except Roman and Tibetan', () {
      final ids = converter.scripts.map((s) => s.id).toList();
      expect(ids, containsAll(['phonetic:hi', 'phonetic:si', 'phonetic:th', 'phonetic:my']));
      expect(ids, isNot(contains('phonetic:ro')));
      expect(ids, isNot(contains('phonetic:tb')));
      expect(ids, isNot(contains('phonetic:br')), reason: 'no phone font');
      expect(ids.toSet().length, ids.length);
      expect(converter.scriptById('phonetic:si')?.label, 'සිංහල');
      expect(converter.scriptById('phonetic:si')?.roman, isFalse);
      expect(converter.scriptById('phonetic:si')?.fontLanguage, 'en');
    });

    test('cleans Roman text of what the Pali tables cannot read', () {
      expect(
        TibetanScriptConverter.rescriptInput("@#/_/bod skyong 'phrin [abc]"),
        '@#/ /bod skyoṅ phrin abc',
      );
      expect(TibetanScriptConverter.rescriptInput('pad+me g.yang'), 'padme gyaṅ');
      expect(TibetanScriptConverter.rescriptInput('bö kül pé'), 'bo kul pe');
    });

    test('rewrites digraphs as the Pali letters the tables expect', () {
      expect(
        TibetanScriptConverter.rescriptInput('tsha dzo zhi wa nyi za tsa'),
        'cha jo shi va ñi sa ca',
      );
    });

    test('gives ཤ and ཞ each script\x27s own ś letter', () {
      expect(converter.convert('ཤུ', 'phonetic:hi'), 'शु');
      expect(converter.convert('ཞི', 'phonetic:hi'), 'शि');
      expect(converter.convert('ཤུ', 'phonetic:si'), 'ශු');
      expect(converter.convert('ཤུ', 'phonetic:th'), 'ศุ');
      expect(converter.convert('ཤེ', 'phonetic:th'), 'เศ');
      expect(converter.convert('ཤུ', 'phonetic:my'), 'ၐု');
      expect(converter.convert('ཤུ', 'phonetic:km'), 'ឝុ');
      expect(converter.convert('ཤུ', 'phonetic:be'), 'শু');
      expect(converter.convert('ཤུ', 'phonetic:te'), 'శు');
      expect(converter.convert('ཤུ', 'phonetic:cy'), 'шу');
    });

    test('never emits private-use glyphs or dangling stackers', () {
      expect(converter.convert('ཉི་ཤུ', 'phonetic:th'), 'ญิ ศุ');
      final my = converter.convert('ཕྱག་འཚལ', 'phonetic:my');
      expect(my, isNot(contains('\u1039')));
      expect(my, endsWith('\u103A'));
      final km = converter.convert('ཕྱག་འཚལ', 'phonetic:km');
      expect(km, isNot(contains('\u17D2')));
      expect(km, endsWith('ល'));
    });

    test('re-scripts the phonetics into Devanagari and Sinhala', () {
      final hi = converter.convert('བོད་སྐྱོང་ལྷ་སྲུང', 'phonetic:hi');
      expect(hi, isNotEmpty);
      expect(hi, matches(_devanagari));
      expect(hi, isNot(matches(_tibetan)));
      expect(hi, isNot(matches(_latinLetters)));
      expect(hi.split(' ').length, 4, reason: 'one word per syllable');
      // bö → bo → बो: no silent letters carried over
      expect(converter.convert('བོད', 'phonetic:hi'), 'बो');

      final si = converter.convert('བོད', 'phonetic:si');
      expect(si, matches(_sinhala));
      expect(si, isNot(matches(_latinLetters)));
    });
  });

  group('Tibetan marks', () {
    const verse = '༄༅། །རྒྱ་གར་སྐད་དུ། ན་མོ།';

    test('keep leaves the Wylie signs in place', () {
      final c = TibetanScriptConverter(markStyle: TibetanMarkStyle.keep);
      expect(c.convert(verse, 'phonetic'), '@#/ /gya gar ke du/ na mo/');
    });

    test('drop removes them and runs the lines on', () {
      final c = TibetanScriptConverter(markStyle: TibetanMarkStyle.drop);
      expect(c.convert(verse, 'phonetic'), 'gya gar ke du na mo');
    });

    test('lineBreak (the default) gives one line per shad, none dangling', () {
      expect(converter.markStyle, TibetanMarkStyle.lineBreak);
      expect(converter.convert(verse, 'phonetic'), 'gya gar ke du\nna mo');
      expect(converter.convert('ན་མོ། །', 'phonetic'), 'na mo');
    });

    test('separator joins the lines with the chosen sign', () {
      final c = TibetanScriptConverter(markStyle: TibetanMarkStyle.separator);
      expect(c.convert(verse, 'phonetic'), 'gya gar ke du | na mo');
      final dot = TibetanScriptConverter(
        markStyle: TibetanMarkStyle.separator,
        separator: '·',
      );
      expect(dot.convert(verse, 'phonetic'), 'gya gar ke du · na mo');
    });

    test('applies to the other scripts and to every shad-like sign', () {
      expect(converter.convert(verse, 'phonetic:hi'), 'ग्य गर् के दु\nन मो');
      expect(
        TibetanScriptConverter.applyMarks('a// b| c: d; e', TibetanMarkStyle.drop),
        'a b c d e',
      );
      expect(
        TibetanScriptConverter.applyMarks(
          '@#!\$% a/ /b   /c',
          TibetanMarkStyle.lineBreak,
        ),
        'a\nb\nc',
      );
      expect(TibetanScriptConverter.applyMarks('1 * 2', TibetanMarkStyle.drop), '1 2');
    });
  });

  test('is registered in the standard service', () {
    final service = TransliterationService.standard();
    expect(service.supports('bo'), isTrue);
    expect(service.supports('BO'), isTrue);
    expect(
      service.convertHtml(
        'བོད་སྐྱོང<br>ལྷ་སྲུང',
        languageCode: 'bo',
        toScriptId: 'phonetic',
      ),
      'bö kyong<br>lha sung',
    );
    final hi = service.convertHtml(
      'བོད་སྐྱོང<br>ལྷ་སྲུང',
      languageCode: 'bo',
      toScriptId: 'phonetic:hi',
    );
    expect(hi, contains('<br>'));
    expect(hi, matches(_devanagari));
  });
}
