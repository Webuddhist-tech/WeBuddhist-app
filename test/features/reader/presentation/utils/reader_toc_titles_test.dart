import 'package:flutter_pecha/features/reader/domain/transliteration/transliteration_service.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_toc_titles.dart';
import 'package:flutter_pecha/features/texts/data/models/text/text_outline.dart';
import 'package:flutter_test/flutter_test.dart';

TextOutlineSection _section(
  String id,
  int number,
  int end, {
  int depth = 0,
  Map<String, String> titles = const {},
}) => TextOutlineSection(
  id: id,
  depth: depth,
  titles: titles,
  segmentId: '$id-verse',
  number: number,
  endNumber: end,
);

/// A Tibetan original: two chapters, the first with two parts.
final _original = TextOutline(
  language: 'bo',
  sections: [
    _section('ch1', 1, 20, titles: {'bo': 'ལེའུ་དང་པོ།'}),
    _section('p1', 1, 10, depth: 1, titles: {'bo': 'ཆ་དང་པོ།'}),
    _section('p2', 11, 20, depth: 1, titles: {'bo': 'ཆ་གཉིས་པ།'}),
    _section('ch2', 21, 40, titles: {'bo': 'ལེའུ་གཉིས་པ།'}),
  ],
);

void main() {
  group('matching a translation\'s titles', () {
    test('a section takes the one opening at its verse, same depth first', () {
      final translation = TextOutline(
        language: 'en',
        sections: [
          _section('e1', 1, 20, titles: {'en': 'Chapter One'}),
          _section('e1a', 1, 10, depth: 1, titles: {'en': 'Part One'}),
          _section('e2', 21, 40, titles: {'en': 'Chapter Two'}),
        ],
      );

      expect(matchTranslationTitles(_original, translation), {
        'ch1': 'Chapter One',
        'p1': 'Part One',
        'ch2': 'Chapter Two',
      });
    });

    test('else the nearest in depth', () {
      final translation = TextOutline(
        language: 'en',
        sections: [_section('e2', 11, 20, titles: {'en': 'The second part'})],
      );

      // p2 opens at verse 11 one level down; the translation's is top-level.
      expect(matchTranslationTitles(_original, translation), {
        'p2': 'The second part',
      });
    });

    test('a translation without a table of contents matches nothing', () {
      expect(
        matchTranslationTitles(_original, const TextOutline.empty()),
        isEmpty,
      );
    });
  });

  group('a section\'s title', () {
    ({String title, String language}) titleOf({
      Map<String, String> titles = const {'bo': 'ལེའུ་དང་པོ།'},
      String? translationTitle,
      String? translationLanguage = 'en',
    }) => readerSectionTitle(
      titles: titles,
      originalLanguage: 'bo',
      translationTitle: translationTitle,
      translationLanguage: translationLanguage,
      textTitle: 'Praises',
      textLanguage: 'en',
    );

    test('the translation has the title', () {
      expect(titleOf(translationTitle: 'Chapter One'), (
        title: 'Chapter One',
        language: 'en',
      ));
    });

    test('the translation has none: the original\'s, in its language', () {
      expect(titleOf(), (title: 'ལེའུ་དང་པོ།', language: 'bo'));
      // Unless the original's table of contents has one in that language.
      expect(
        titleOf(titles: const {'bo': 'ལེའུ་དང་པོ།', 'en': 'First chapter'}),
        (title: 'First chapter', language: 'en'),
      );
    });

    test('neither has one: the text\'s title', () {
      expect(titleOf(titles: const {}), (title: 'Praises', language: 'en'));
    });

    test('with no translation showing, its title is not used', () {
      expect(
        titleOf(translationTitle: 'Chapter One', translationLanguage: null),
        (title: 'ལེའུ་དང་པོ།', language: 'bo'),
      );
    });
  });

  group('the page\'s sections', () {
    TextOutlineSection child(String id, int number, int end) => TextOutlineSection(
      id: id,
      parentId: 'root',
      depth: 1,
      titles: const {'bo': 'ཀ'},
      segmentId: '$id-verse',
      number: number,
      endNumber: end,
    );

    test('a heading whose parts hold all its verses only groups them', () {
      final sections = [
        _section('root', 1, 32),
        child('meaning', 1, 2),
        child('praise', 3, 28),
        child('benefits', 29, 31),
        child('colophon', 32, 32),
      ];
      expect(readerPageSections(sections).map((s) => s.id), [
        'meaning',
        'praise',
        'benefits',
        'colophon',
      ]);
    });

    test('one with verses of its own is a section too', () {
      // Verses 3-4 sit directly under the root.
      final sections = [
        _section('root', 1, 10),
        child('a', 1, 2),
        child('b', 5, 10),
      ];
      expect(readerPageSections(sections).map((s) => s.id), [
        'root',
        'a',
        'b',
      ]);
    });
  });

  group('the section a verse is in', () {
    test('is the innermost holding it', () {
      final sections = _original.sections;
      expect(innermostSectionHolding(sections, 1)?.id, 'p1');
      expect(innermostSectionHolding(sections, 15)?.id, 'p2');
      expect(innermostSectionHolding(sections, 30)?.id, 'ch2');
    });

    test('the parent when the verse is past its subsections', () {
      final sections = [
        _section('ch1', 1, 20),
        _section('p1', 1, 5, depth: 1),
      ];
      expect(innermostSectionHolding(sections, 12)?.id, 'ch1');
    });

    test('none before the first or after the last', () {
      final sections = [_section('late', 5, 9)];
      expect(innermostSectionHolding(sections, 2), isNull);
      expect(innermostSectionHolding(sections, 12), isNull);
    });
  });

  group('titles in the original\'s script', () {
    final service = TransliterationService.standard();
    const heading = '༄༅། །སྒྲོལ་མ་ཉེར་གཅིག་ལ་བསྟོད་པ།';

    String inScript(String title, String? scriptId, {String language = 'bo'}) =>
        readerTitleInScript(
          service,
          title: title,
          language: language,
          scriptId: scriptId,
        );

    test('a Tibetan heading in Roman phonetics', () {
      expect(inScript(heading, 'phonetic'), 'dröl ma nyer chik la tö pa');
    });

    test('a Tibetan heading in Devanagari', () {
      expect(inScript(heading, 'phonetic:hi'), 'द्रोल् म ञेर् छिक् ल तो प');
    });

    test('no script, or no converter for the language: as written', () {
      expect(inScript(heading, null), heading);
      expect(
        inScript('Praises to Tārā', 'phonetic', language: 'en'),
        'Praises to Tārā',
      );
    });

    test('the leading marks go before converting, on one line', () {
      expect(stripTitleMarks(heading), 'སྒྲོལ་མ་ཉེར་གཅིག་ལ་བསྟོད་པ།');
      expect(stripTitleMarks('༄༅།'), '');
      // Shads inside a title break lines in phonetics; a title stays on one.
      final twoLines = inScript('བསྟོད་པ། །དངོས།', 'phonetic');
      expect(twoLines, isNot(contains('<br>')));
      expect(twoLines, isNot(contains('\n')));
    });

    test('a title of marks alone stays as it is', () {
      expect(inScript('༄༅།', 'phonetic'), '༄༅།');
    });

    test('a Pali title written in Roman, in Devanagari', () {
      expect(
        inScript('Tisaraṇa Aṭṭhasīla', 'hi', language: 'pi'),
        'तिसरण अट्ठसील',
      );
    });
  });

  group('a text\'s title as the page shows it', () {
    final service = TransliterationService.standard();
    const original = 'སྒྲོལ་མ་ཉེར་གཅིག་ལ་བསྟོད་པ།';

    ({String title, String language}) titleOf({
      String? scriptId,
      String? translationTitle,
      String? translationLanguage,
    }) => readerTextTitle(
      service,
      title: original,
      language: 'bo',
      scriptId: scriptId,
      translationTitle: translationTitle,
      translationLanguage: translationLanguage,
    );

    test('a shown translation names the text in its language', () {
      final title = titleOf(
        scriptId: 'phonetic',
        translationTitle: 'Praises to the Twenty-One Tārās',
        translationLanguage: 'en',
      );
      expect(title.title, 'Praises to the Twenty-One Tārās');
      expect(title.language, 'en');
    });

    test('a translation without a title leaves the original\'s', () {
      final title = titleOf(translationTitle: '', translationLanguage: 'en');
      expect(title.title, original);
      expect(title.language, 'bo');
    });

    test('without a translation: the original, in its script', () {
      expect(titleOf(), (title: original, language: 'bo'));
      final roman = titleOf(scriptId: 'phonetic');
      expect(roman.title, 'dröl ma nyer chik la tö pa');
      expect(
        roman.language,
        service.fontLanguageFor('bo', 'phonetic') ?? 'bo',
      );
    });
  });
}
