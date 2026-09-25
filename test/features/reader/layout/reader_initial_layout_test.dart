import 'package:flutter_pecha/features/reader/domain/layout/reader_initial_layout.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/script_converter.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/transliteration_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = TransliterationService.standard();
  final tibetanScripts = service.converterFor('bo')!.scripts;
  final paliScripts = service.converterFor('pi')!.scripts;

  /// Praises to the 21 Tārās: Tibetan with an English translation only.
  const praiseTranslations = ['en'];

  /// Exhorting the Protectors of Tibet: Tibetan with six translations.
  const sadhanaTranslations = ['vi', 'ne', 'mn', 'hi', 'zh', 'en'];

  /// A Bodhicharyavatara plan text: English root with translations.
  const englishRootTranslations = ['hi', 'mn', 'ne', 'vi', 'zh'];

  ReaderInitialLayout? resolve({
    required ReaderLayoutContext context,
    String textLanguage = 'bo',
    required String uiLanguage,
    Iterable<String> translationLanguages = praiseTranslations,
    Iterable<TransliterationScript>? converterScripts,
    String? listLanguage,
  }) => resolveInitialLayout(
    context: context,
    textLanguage: textLanguage,
    uiLanguage: uiLanguage,
    translationLanguages: translationLanguages,
    converterScripts: converterScripts ?? tibetanScripts,
    listLanguage: listLanguage,
  );

  const asWritten = ReaderInitialLayout.asWritten();

  ReaderInitialLayout bothOn({String? script, required String translation}) =>
      ReaderInitialLayout(
        originalVisible: true,
        originalScriptId: script,
        translationOn: true,
        translationLanguage: translation,
      );

  ReaderInitialLayout translationOnly(String language) => ReaderInitialLayout(
    originalVisible: false,
    translationOn: true,
    translationLanguage: language,
  );

  group('ReaderInitialLayout', () {
    test('a translation that is on needs a language', () {
      expect(
        () => ReaderInitialLayout(originalVisible: true, translationOn: true),
        throwsA(isA<AssertionError>()),
      );
    });

    test('one layer is always on', () {
      expect(
        () => ReaderInitialLayout(originalVisible: false, translationOn: false),
        throwsA(isA<AssertionError>()),
      );
    });

    test('compares by value', () {
      expect(
        bothOn(script: 'phonetic', translation: 'en'),
        bothOn(script: 'phonetic', translation: 'en'),
      );
      expect(asWritten, isNot(translationOnly('en')));
    });
  });

  group('scriptIdForUiLanguage', () {
    test('Tibetan texts: Roman for English and Chinese, Devanagari for Hindi '
        'and Nepali, Cyrillic for Mongolian, as written for Tibetan', () {
      expect(scriptIdForUiLanguage('en', tibetanScripts), 'phonetic');
      expect(scriptIdForUiLanguage('zh', tibetanScripts), 'phonetic');
      expect(scriptIdForUiLanguage('hi', tibetanScripts), 'phonetic:hi');
      expect(scriptIdForUiLanguage('ne', tibetanScripts), 'phonetic:hi');
      expect(scriptIdForUiLanguage('mn', tibetanScripts), 'phonetic:cy');
      expect(scriptIdForUiLanguage('bo', tibetanScripts), isNull);
    });

    test('Pali texts use the Pali converter ids', () {
      expect(scriptIdForUiLanguage('en', paliScripts), 'ro');
      expect(scriptIdForUiLanguage('hi', paliScripts), 'hi');
      expect(scriptIdForUiLanguage('mn', paliScripts), 'cy');
    });

    test('a language without an app translation reads Roman', () {
      expect(scriptIdForUiLanguage('vi', tibetanScripts), 'phonetic');
      expect(scriptIdForUiLanguage('pi', tibetanScripts), 'phonetic');
    });

    test('codes are trimmed and lower-cased', () {
      expect(scriptIdForUiLanguage(' HI ', tibetanScripts), 'phonetic:hi');
      expect(scriptIdForUiLanguage('BO', tibetanScripts), isNull);
    });

    test('a script the converter lacks falls back to Roman', () {
      const romanOnly = [
        TransliterationScript(
          id: 'latin',
          name: 'Roman',
          nativeName: 'Roman',
          roman: true,
          codePointRanges: [
            [0x41, 0x7A],
          ],
        ),
      ];
      expect(scriptIdForUiLanguage('hi', romanOnly), 'latin');
      expect(scriptIdForUiLanguage('mn', romanOnly), 'latin');
    });

    test('no converter means as written', () {
      expect(scriptIdForUiLanguage('en', const []), isNull);
      expect(scriptIdForUiLanguage('hi', const []), isNull);
    });
  });

  group('resolveInitialLayout: library', () {
    test('leaves the global settings alone', () {
      for (final ui in ['en', 'bo', 'zh', 'hi', 'mn', 'ne']) {
        expect(
          resolve(context: ReaderLayoutContext.library, uiLanguage: ui),
          isNull,
          reason: ui,
        );
      }
    });
  });

  group('resolveInitialLayout: event', () {
    test('Tara praise: Roman + English for English readers', () {
      expect(
        resolve(context: ReaderLayoutContext.event, uiLanguage: 'en'),
        bothOn(script: 'phonetic', translation: 'en'),
      );
    });

    test('Tara praise: Chinese readers get Roman and fall back to English', () {
      expect(
        resolve(context: ReaderLayoutContext.event, uiLanguage: 'zh'),
        bothOn(script: 'phonetic', translation: 'en'),
      );
    });

    test('Tara praise: Hindi readers get Devanagari and fall back to English', () {
      expect(
        resolve(context: ReaderLayoutContext.event, uiLanguage: 'hi'),
        bothOn(script: 'phonetic:hi', translation: 'en'),
      );
    });

    test('Tara praise: Mongolian readers get Cyrillic and English', () {
      expect(
        resolve(context: ReaderLayoutContext.event, uiLanguage: 'mn'),
        bothOn(script: 'phonetic:cy', translation: 'en'),
      );
    });

    test('Tara praise: Tibetan readers see it as written, no translation', () {
      expect(
        resolve(context: ReaderLayoutContext.event, uiLanguage: 'bo'),
        asWritten,
      );
    });

    test('sadhana: the UI language translation when the text offers it', () {
      expect(
        resolve(
          context: ReaderLayoutContext.event,
          uiLanguage: 'hi',
          translationLanguages: sadhanaTranslations,
        ),
        bothOn(script: 'phonetic:hi', translation: 'hi'),
      );
      expect(
        resolve(
          context: ReaderLayoutContext.event,
          uiLanguage: 'zh',
          translationLanguages: sadhanaTranslations,
        ),
        bothOn(script: 'phonetic', translation: 'zh'),
      );
      expect(
        resolve(
          context: ReaderLayoutContext.event,
          uiLanguage: 'ne',
          translationLanguages: sadhanaTranslations,
        ),
        bothOn(script: 'phonetic:hi', translation: 'ne'),
      );
      expect(
        resolve(
          context: ReaderLayoutContext.event,
          uiLanguage: 'mn',
          translationLanguages: sadhanaTranslations,
        ),
        bothOn(script: 'phonetic:cy', translation: 'mn'),
      );
    });

    test('a Tibetan text with no translation at all: Roman only', () {
      expect(
        resolve(
          context: ReaderLayoutContext.event,
          uiLanguage: 'en',
          translationLanguages: const [],
        ),
        const ReaderInitialLayout(
          originalVisible: true,
          originalScriptId: 'phonetic',
          translationOn: false,
        ),
      );
    });

    test('an English text: no script, the UI language translation when offered', () {
      expect(
        resolve(
          context: ReaderLayoutContext.event,
          textLanguage: 'en',
          uiLanguage: 'hi',
          translationLanguages: englishRootTranslations,
          converterScripts: const [],
        ),
        bothOn(translation: 'hi'),
      );
    });

    test('an English text never falls back to an English translation of itself', () {
      expect(
        resolve(
          context: ReaderLayoutContext.event,
          textLanguage: 'en',
          uiLanguage: 'bo',
          translationLanguages: englishRootTranslations,
          converterScripts: const [],
        ),
        asWritten,
      );
    });

    test('a text already in the UI language is shown as written', () {
      expect(
        resolve(
          context: ReaderLayoutContext.event,
          textLanguage: 'en',
          uiLanguage: 'en',
          translationLanguages: englishRootTranslations,
          converterScripts: const [],
        ),
        asWritten,
      );
    });

    test('a Pali text uses the Pali scripts', () {
      expect(
        resolve(
          context: ReaderLayoutContext.event,
          textLanguage: 'pi',
          uiLanguage: 'hi',
          translationLanguages: const [],
          converterScripts: paliScripts,
        ),
        const ReaderInitialLayout(
          originalVisible: true,
          originalScriptId: 'hi',
          translationOn: false,
        ),
      );
    });

    test('language codes are compared after trimming and lower-casing', () {
      expect(
        resolve(
          context: ReaderLayoutContext.event,
          textLanguage: 'BO',
          uiLanguage: ' En',
          translationLanguages: const ['EN '],
        ),
        bothOn(script: 'phonetic', translation: 'en'),
      );
    });
  });

  group('resolveInitialLayout: plan', () {
    test('only the UI language translation when the text offers it', () {
      expect(
        resolve(
          context: ReaderLayoutContext.plan,
          uiLanguage: 'hi',
          translationLanguages: sadhanaTranslations,
        ),
        translationOnly('hi'),
      );
      expect(
        resolve(context: ReaderLayoutContext.plan, uiLanguage: 'en'),
        translationOnly('en'),
      );
    });

    test('as written when the UI language is not offered: no English fallback', () {
      expect(
        resolve(context: ReaderLayoutContext.plan, uiLanguage: 'zh'),
        asWritten,
      );
    });

    test('Tibetan readers see a Tibetan text as written', () {
      expect(
        resolve(
          context: ReaderLayoutContext.plan,
          uiLanguage: 'bo',
          translationLanguages: sadhanaTranslations,
        ),
        asWritten,
      );
    });

    test('an English plan text reads as written in English, Hindi only in Hindi', () {
      expect(
        resolve(
          context: ReaderLayoutContext.plan,
          textLanguage: 'en',
          uiLanguage: 'en',
          translationLanguages: englishRootTranslations,
          converterScripts: const [],
        ),
        asWritten,
      );
      expect(
        resolve(
          context: ReaderLayoutContext.plan,
          textLanguage: 'en',
          uiLanguage: 'hi',
          translationLanguages: englishRootTranslations,
          converterScripts: const [],
        ),
        translationOnly('hi'),
      );
    });

    test('never picks a script', () {
      final layout = resolve(
        context: ReaderLayoutContext.plan,
        uiLanguage: 'hi',
        translationLanguages: sadhanaTranslations,
      );
      expect(layout!.originalScriptId, isNull);
    });
  });

  group('resolveInitialLayout: chant', () {
    test('the edition the list handed over is shown as written', () {
      // Hindi UI, Hindi list: the reader loaded the Hindi edition.
      expect(
        resolve(
          context: ReaderLayoutContext.chant,
          textLanguage: 'hi',
          uiLanguage: 'hi',
          translationLanguages: const ['vi', 'ne', 'mn', 'zh', 'en'],
          converterScripts: const [],
          listLanguage: 'hi',
        ),
        asWritten,
      );
      // English UI, tapped Tibetan in the list.
      expect(
        resolve(
          context: ReaderLayoutContext.chant,
          uiLanguage: 'en',
          translationLanguages: sadhanaTranslations,
          listLanguage: 'bo',
        ),
        asWritten,
      );
    });

    test('the list language is compared like every other code', () {
      expect(
        resolve(
          context: ReaderLayoutContext.chant,
          uiLanguage: 'en',
          translationLanguages: sadhanaTranslations,
          listLanguage: ' BO ',
        ),
        asWritten,
      );
    });

    test('without a list language it behaves like a plan', () {
      expect(
        resolve(
          context: ReaderLayoutContext.chant,
          uiLanguage: 'hi',
          translationLanguages: sadhanaTranslations,
        ),
        translationOnly('hi'),
      );
      expect(
        resolve(
          context: ReaderLayoutContext.chant,
          uiLanguage: 'hi',
          translationLanguages: sadhanaTranslations,
          listLanguage: '',
        ),
        translationOnly('hi'),
      );
    });

    test('a list language the edition could not honour falls back to the plan rule', () {
      // Tapped Hindi, but the reader still loaded the Tibetan edition.
      expect(
        resolve(
          context: ReaderLayoutContext.chant,
          uiLanguage: 'hi',
          translationLanguages: sadhanaTranslations,
          listLanguage: 'hi',
        ),
        translationOnly('hi'),
      );
      expect(
        resolve(
          context: ReaderLayoutContext.chant,
          uiLanguage: 'zh',
          translationLanguages: praiseTranslations,
          listLanguage: 'zh',
        ),
        asWritten,
      );
    });
  });

  group('translationCandidates', () {
    test('remembered pick first, then the seeded default, then the fallback', () {
      expect(
        translationCandidates(remembered: 'zh', seeded: 'hi', fallback: 'en'),
        ['zh', 'hi', 'en'],
      );
    });

    test('drops blanks and repeats, and normalises codes', () {
      expect(
        translationCandidates(remembered: ' EN', seeded: 'en', fallback: 'en '),
        ['en'],
      );
      expect(
        translationCandidates(remembered: '', seeded: null, fallback: 'hi'),
        ['hi'],
      );
    });

    test('a blank fallback yields nothing to try', () {
      expect(translationCandidates(fallback: ' '), isEmpty);
    });
  });
}
