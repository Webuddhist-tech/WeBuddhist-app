import 'package:flutter_pecha/features/reader/domain/transliteration/pali_script_converter.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/tibetan_script_converter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pali_script_convertor/pali_script_convertor.dart' as psc;

void main() {
  final tibetan = TibetanScriptConverter();
  final pali = PaliScriptConverter();

  group('ScriptConverter.detectScript', () {
    test('reads the script the letters are in', () {
      expect(tibetan.detectScript('བཀྲ་ཤིས་བདེ་ལེགས།'), 'tibetan');
      expect(pali.detectScript('नमो तस्स भगवतो'), psc.Scripts.hi);
      expect(pali.detectScript('නමො තස්ස භගවතො'), psc.Scripts.si);
    });

    test('a Latin-only sample is Roman', () {
      expect(tibetan.detectScript('tra shi de lek'), 'phonetic');
      expect(pali.detectScript('namo tassa bhagavato'), psc.Scripts.ro);
    });

    test('stray Latin does not outvote the script the text is in', () {
      // An editorial siglum or a loanword sitting inside a native-script
      // verse: the Latin is incidental, the verse is not. Counting both on
      // equal terms reported Roman for a text plainly in Uchen.
      expect(
        tibetan.detectScript('བཀྲ་ཤིས། (see Derge vol. 5, page 12, PTS ed.)'),
        'tibetan',
      );
      expect(
        pali.detectScript('नमो (So PTS; see the Burmese edition, page 12.)'),
        psc.Scripts.hi,
      );
    });

    test('is null when no known script appears', () {
      expect(tibetan.detectScript(''), isNull);
      // Tibetan digits and punctuation are outside every script's ranges.
      expect(tibetan.detectScript('༡༢༣ ། ༎'), isNull);
    });
  });
}
