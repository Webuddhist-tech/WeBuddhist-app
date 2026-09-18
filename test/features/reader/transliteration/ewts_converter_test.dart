import 'dart:io';

import 'package:flutter_pecha/features/reader/domain/transliteration/ewts/ewts_converter.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixtures = 'test/features/reader/transliteration/fixtures';

String _read(String name) => File('$_fixtures/$name')
    .readAsStringSync()
    .replaceFirst('﻿', '')
    .replaceAll('\r\n', '\n');

/// jsewts' kangtest normalisation: spacing is not part of the comparison,
/// and a double shad may come back as two single ones.
String _loose(String s) => s.replaceAll(' ', '').replaceAll('༎', '།།');

void main() {
  final strict = EwtsConverter();
  final lenient = EwtsConverter(checkStrict: false);

  group('EwtsConverter — BDRC conversion corpus', () {
    // Same procedure as jsewts test/wylie.test.js: Wylie → Unicode with and
    // without strict checks, back to Wylie, and back to Unicode again.
    final lines = _read('ewts_test_cases.txt').split('\n');
    var cases = 0;
    for (var lineNo = 0; lineNo < lines.length; lineNo++) {
      final line = lines[lineNo];
      if (line.isEmpty || line.startsWith('#')) continue;
      final f = line.split('\t');
      if (f.length != 6) {
        throw StateError('corpus line ${lineNo + 1} needs 6 fields: "$line"');
      }
      final wylie = f[0];
      final uni = f[1];
      final warnsCode = int.parse(f[2]);
      final wylieBack = f[3];
      final wylieWarns = int.parse(f[4]);
      final uniDiffers = int.parse(f[5]) > 0;
      cases++;

      test('line ${lineNo + 1}: "$wylie"', () {
        final e = <String>[];
        final s = lenient.toUnicode(wylie, warns: e);
        final e2 = <String>[];
        final s2 = strict.toUnicode(wylie, warns: e2);
        final e3 = <String>[];
        final rewylie = strict.toWylie(s, warns: e3);
        final reuni = strict.toUnicode(rewylie);

        expect(s2, s, reason: 'strict and lenient checks change no output');
        expect(s, uni, reason: 'unicode');
        if (e.isNotEmpty) {
          expect(e2, isNotEmpty, reason: 'lenient warnings imply strict ones');
        }
        switch (warnsCode) {
          case 0:
            expect(e, isEmpty, reason: 'no lenient warnings expected');
            expect(e2, isEmpty, reason: 'no strict warnings expected');
          case 1:
            expect(e, isEmpty, reason: 'no lenient warnings expected');
            expect(e2, isNotEmpty, reason: 'strict warnings expected');
          default:
            expect(e, isNotEmpty, reason: 'lenient warnings expected');
        }
        expect(rewylie, wylieBack, reason: 'wylie back');
        if (wylieWarns == 0) {
          expect(e3, isEmpty, reason: 'no toWylie warnings expected');
        } else {
          expect(e3, isNotEmpty, reason: 'toWylie warnings expected');
        }
        if (uniDiffers) {
          expect(reuni, isNot(s), reason: 'should not round-trip');
        } else {
          expect(reuni, s, reason: 'should round-trip');
        }
      });
    }
    test('corpus was read', () => expect(cases, greaterThan(200)));
  });

  group('EwtsConverter — Kangyur sample (BDRC jsewts test corpus)', () {
    final uniLines = _read('kangyur_sample_unicode.txt').split('\n');
    final wylieLines = _read('kangyur_sample_wylie.txt').split('\n');

    test('fixtures are aligned', () {
      expect(uniLines.length, wylieLines.length);
      expect(uniLines.where((l) => l.trim().isNotEmpty).length, greaterThan(15));
    });

    for (var i = 0; i < uniLines.length; i++) {
      if (uniLines[i].trim().isEmpty) continue;
      test('line ${i + 1} to Wylie', () {
        expect(strict.toWylie(uniLines[i]), wylieLines[i]);
      });
      test('line ${i + 1} back to Unicode', () {
        expect(
          _loose(strict.toUnicode(wylieLines[i], sloppy: false)),
          _loose(uniLines[i]),
        );
      });
    }
  });

  group('EwtsConverter.toWylie — syllables', () {
    String wylie(String s) => strict.toWylie(s);

    test('root + suffix, prefix + root + suffix', () {
      expect(wylie('དག'), 'dag');
      expect(wylie('བསམ'), 'bsam');
      expect(wylie('མཁས'), 'mkhas');
      expect(wylie('གནས'), 'gnas');
      expect(wylie('བདག'), 'bdag');
      expect(wylie('ཤགས'), 'shags');
      expect(wylie('བཏགས'), 'btags');
    });

    test('a-chung as suffix and as a particle', () {
      expect(wylie('དགའ'), "dga'");
      expect(wylie('བཀའ'), "bka'");
      expect(wylie('བའི'), "ba'i");
      expect(wylie('དཔའི'), "dpa'i");
      expect(wylie('འདིའི'), "'di'i");
      expect(wylie('འོད'), "'od");
    });

    test('stacks: superscribed, subjoined, and prefixed stacks', () {
      expect(wylie('བསྒྲུབས'), 'bsgrubs');
      expect(wylie('བཀྲ་ཤིས'), 'bkra shis');
      expect(wylie('སྐྱོང'), 'skyong');
      expect(wylie('ལྷ'), 'lha');
      expect(wylie('འཕྲིན'), "'phrin");
      expect(wylie('རྣམས'), 'rnams');
    });

    test('prefix g before root y is written g.y', () {
      expect(wylie('གཡང'), 'g.yang');
      expect(wylie('གྱང'), 'gyang');
    });

    test('ambiguous three-letter syllables use the dictionary', () {
      expect(wylie('དགས'), 'dgas');
      expect(wylie('མངས'), 'mangs');
      expect(wylie('བགས'), 'bags');
    });

    test('non-native stacks and Sanskrit marks use +, long vowels, ~M', () {
      expect(wylie('ཨོཾ་མ་ཎི་པདྨེ་ཧཱུྃ'), 'oM ma Ni pad+me hU~M');
      // dz+r is in BDRC's stack list, so no "+" (corpus: "badzra gu ru").
      expect(wylie('བཛྲ'), 'badzra');
      expect(wylie('ཨཱཿ'), 'AH');
      expect(wylie('ཨ'), 'a');
    });
  });

  group('EwtsConverter.toWylie — text', () {
    test('the opening verse of Exhorting the Protectors of Tibet', () {
      expect(
        strict.toWylie('༄༅། །བོད་སྐྱོང་ལྷ་སྲུང་གི་འཕྲིན་བསྐུལ།'),
        "@#/_/bod skyong lha srung gi 'phrin bskul/",
      );
    });

    test('the Bodhicharyavatara title line', () {
      expect(
        strict.toWylie('བྱང་ཆུབ་སེམས་དཔའི་སྤྱོད་པ་ལ་འཇུག་པ་བཞུགས་སོ། །'),
        "byang chub sems dpa'i spyod pa la 'jug pa bzhugs so/_/",
      );
    });

    test('digits, double shad, escaped non-Tibetan text', () {
      expect(strict.toWylie('བདེ་བ་ཅན་༡༩༎'), 'bde ba can 19//');
      expect(strict.toWylie('abc, 12'), '[abc, 12]');
      expect(strict.toWylie('abc, 12', escape: false), 'abc, 12');
      expect(strict.toWylie(''), '');
    });

    test('Wylie → Unicode round trip of a verse', () {
      const verse = 'བོད་སྐྱོང་ལྷ་སྲུང་གི་འཕྲིན་བསྐུལ།';
      final warns = <String>[];
      expect(strict.toUnicode(strict.toWylie(verse), warns: warns), verse);
      expect(warns, isEmpty);
    });
  });
}
