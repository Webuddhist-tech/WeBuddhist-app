import 'package:flutter_pecha/features/reader/domain/transliteration/script_converter.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/transliteration_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Upper-cases every chunk it is handed, so tests can see exactly which
/// parts of the HTML reached the converter.
class _ShoutingConverter extends ScriptConverter {
  int calls = 0;

  @override
  String get languageCode => 'xx';

  @override
  List<TransliterationScript> get scripts => const [
    TransliterationScript(
      id: 'up',
      name: 'Upper',
      nativeName: 'UPPER',
      codePointRanges: [
        [0x61, 0x7A],
      ],
      fontLanguage: 'en',
    ),
  ];

  @override
  String convert(String text, String toScriptId) {
    calls++;
    if (toScriptId != 'up') throw ArgumentError('Unsupported $toScriptId');
    return text.toUpperCase();
  }
}

void main() {
  late _ShoutingConverter converter;
  late TransliterationService service;

  setUp(() {
    converter = _ShoutingConverter();
    service = TransliterationService([converter]);
  });

  group('TransliterationService.converterFor', () {
    test('matches language codes case-insensitively', () {
      expect(service.converterFor('xx'), same(converter));
      expect(service.converterFor(' XX '), same(converter));
      expect(service.supports('bo'), isFalse);
    });

    test('resolves scripts and font languages through the converter', () {
      expect(service.script('xx', 'up')?.label, 'UPPER');
      expect(service.script('xx', 'nope'), isNull);
      expect(service.script('bo', 'up'), isNull);
      expect(service.fontLanguageFor('xx', 'up'), 'en');
    });
  });

  group('TransliterationService.convertHtml', () {
    test('converts text but leaves tags and entities alone', () {
      final out = service.convertHtml(
        'namo<br>tassa &amp; <sup class="footnote-marker">1</sup>',
        languageCode: 'xx',
        toScriptId: 'up',
      );
      expect(
        out,
        'NAMO<br>TASSA &amp; <sup class="footnote-marker">1</sup>',
      );
    });

    test('turns line breaks a converter adds into <br> tags', () {
      final service = TransliterationService.standard();
      expect(
        service.convertHtml(
          'རྒྱ་གར། ན་མོ།<br>ཨོཾ།',
          languageCode: 'bo',
          toScriptId: 'phonetic',
        ),
        'gya gar<br>na mo<br>om',
      );
    });

    group('footnotes', () {
      test('leaves a footnote body and its marker as the editor wrote them', () {
        // The note is the editor's English ("So PTS; see ..."), not the
        // verse, so running it through the converter turns it to gibberish.
        final out = service.convertHtml(
          'namo<sup class="footnote-marker">*</sup>'
          '<i class="footnote">So PTS; see page 12.</i> tassa',
          languageCode: 'xx',
          toScriptId: 'up',
        );
        expect(
          out,
          'NAMO<sup class="footnote-marker">*</sup>'
          '<i class="footnote">So PTS; see page 12.</i> TASSA',
        );
      });

      test('skips the whole footnote, nested tags and all', () {
        final out = service.convertHtml(
          '<i class="footnote">see <i>op. cit.</i> page 12</i>namo',
          languageCode: 'xx',
          toScriptId: 'up',
        );
        expect(
          out,
          '<i class="footnote">see <i>op. cit.</i> page 12</i>NAMO',
        );
      });

      test('a self-closing footnote tag does not swallow the verse', () {
        final out = service.convertHtml(
          '<img class="footnote-marker"/>namo',
          languageCode: 'xx',
          toScriptId: 'up',
        );
        expect(out, '<img class="footnote-marker"/>NAMO');
      });

      test('other classes are still converted', () {
        final out = service.convertHtml(
          '<span class="verse">namo</span>',
          languageCode: 'xx',
          toScriptId: 'up',
        );
        expect(out, '<span class="verse">NAMO</span>');
      });
    });

    test('a newline in the source does not cancel the breaks it adds', () {
      // Newlines in an HTML text node are whitespace, not breaks. A
      // pretty-printed document used to lose every <br> the mark style made.
      final service = TransliterationService.standard();
      expect(
        service.convertHtml(
          'རྒྱ་གར།\nན་མོ།',
          languageCode: 'bo',
          toScriptId: 'phonetic',
        ),
        'gya gar\nna mo',
      );
      expect(
        service.convertHtml(
          'རྒྱ་གར། ན་མོ།\nཨོཾ། ཨོཾ།',
          languageCode: 'bo',
          toScriptId: 'phonetic',
        ),
        'gya gar<br>na mo\nom<br>om',
      );
    });

    test('returns the input unchanged for an unsupported language', () {
      expect(
        service.convertHtml('namo', languageCode: 'bo', toScriptId: 'up'),
        'namo',
      );
      expect(converter.calls, 0);
    });

    test('returns the input unchanged when the converter throws', () {
      expect(
        service.convertHtml('namo', languageCode: 'xx', toScriptId: 'bad'),
        'namo',
      );
    });

    test('memoises per language, script and html', () {
      service.convertHtml('namo', languageCode: 'xx', toScriptId: 'up');
      service.convertHtml('namo', languageCode: 'xx', toScriptId: 'up');
      expect(converter.calls, 1);
      expect(service.cachedEntries, 1);

      service.convertHtml('tassa', languageCode: 'xx', toScriptId: 'up');
      expect(converter.calls, 2);
      expect(service.cachedEntries, 2);
    });

    test('drops the oldest entry once the cache is full', () {
      for (var i = 0; i <= TransliterationService.maxCachedEntries; i++) {
        service.convertHtml('n$i', languageCode: 'xx', toScriptId: 'up');
      }
      expect(service.cachedEntries, TransliterationService.maxCachedEntries);
      // The first entry was evicted, so converting it again does real work.
      final before = converter.calls;
      service.convertHtml('n0', languageCode: 'xx', toScriptId: 'up');
      expect(converter.calls, before + 1);
    });
  });
}
