import 'package:flutter_pecha/features/reader/domain/transliteration/tibetan_phonetics.dart';
import 'package:flutter_test/flutter_test.dart';

String ph(String s) => TibetanPhonetics.transcribe(s);

void main() {
  group('TibetanPhonetics — names with known THL renderings', () {
    test('prefixes and superscripts are silent, suffixes colour the vowel', () {
      expect(ph('བཀྲ་ཤིས'), 'tra shi'); // Trashi
      expect(ph('བསྟན་འཛིན'), 'ten dzin'); // Tendzin
      expect(ph('རྡོ་རྗེ'), 'do je'); // Dorje
      expect(ph('ཆོས་འཕེལ'), 'chö pel'); // Chöpel
      expect(ph('དཔལ་ལྡན'), 'pel den'); // Pelden
      expect(ph('ཕུན་ཚོགས'), 'pün tsok'); // Püntsok
      expect(ph('མཁས་གྲུབ'), 'khe drup'); // Khedrup
      expect(ph('དགེ་ལུགས'), 'ge luk'); // Geluk
      expect(ph('བཀའ་བརྒྱུད'), 'ka gyü'); // Kagyü
    });

    test('db → w, dby → y, zl → d, py/by → ch/j, my → ny', () {
      expect(ph('དབང་ཕྱུག'), 'wang chuk'); // Wangchuk
      expect(ph('དབྱངས་ཅན'), 'yang chen'); // Yangchen
      expect(ph('དབུ་མ'), 'u ma'); // Uma
      expect(ph('ཟླ་བ'), 'da wa'); // Dawa
      expect(ph('བྱང་ཆུབ'), 'jang chup'); // Jangchup
      expect(ph('སྤྱོད་པ'), 'chö pa'); // Chöpa
      expect(ph('དམྱལ་བ'), 'nyel wa'); // Nyelwa
    });

    test('stacks: sakya, nyingma, drukpa, lhasa, tsongkhapa, rinpoche', () {
      expect(ph('ས་སྐྱ'), 'sa kya');
      expect(ph('རྙིང་མ'), 'nying ma');
      expect(ph('འབྲུག་པ'), 'druk pa');
      expect(ph('ལྷ་ས'), 'lha sa');
      expect(ph('ཙོང་ཁ་པ'), 'tsong kha pa');
      expect(ph('རིན་པོ་ཆེ'), 'rin po che');
      expect(ph('གཡང'), 'yang');
    });

    test('nasal before an a-chung prefix', () {
      expect(ph('མཁའ་འགྲོ'), 'khan dro'); // Khandro
      expect(ph('དགེ་འདུན'), 'gen dün'); // Gendün
      expect(ph('རྒྱ་གར'), 'gya gar'); // no a-chung, no nasal
    });

    test('the nasal never crosses a shad', () {
      expect(ph('འདྲ་མ། །འཇིག་རྟེན'), 'dra ma/ /jik ten');
    });

    test('particles and a-chung roots', () {
      expect(ph('དཔའི'), 'pé'.replaceAll('é', 'e'));
      expect(ph('བའི'), 'be');
      expect(ph('འོད'), 'ö');
      expect(ph('དེའོ'), 'deo');
    });

    test('Sanskrit mantra', () {
      expect(ph('ཨོཾ་མ་ཎི་པདྨེ་ཧཱུྃ'), 'om ma ni padme hung');
      expect(ph('ཨཱཿ'), 'ah');
    });
  });

  group('TibetanPhonetics — text', () {
    test('the opening verse of Exhorting the Protectors of Tibet', () {
      expect(
        ph('༄༅། །བོད་སྐྱོང་ལྷ་སྲུང་གི་འཕྲིན་བསྐུལ།'),
        '@#/ /bö kyong lha sung gi trin kül/',
      );
    });

    test('second verse', () {
      expect(
        ph('ཀྱེ་མ་རྨད་བསོད་ནམས་མཐུ་དང་སྨོན་ལམ་གྱིས།'),
        'kye ma me sö nam tu dang mön lam gyi/',
      );
    });

    test('digits and non-Tibetan text pass through', () {
      expect(ph('བདེ་བ་ཅན་༡༩'), 'de wa chen 19');
      expect(ph('abc'), 'abc');
      expect(ph(''), '');
    });
  });
}
