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
