import 'package:flutter_pecha/features/reader/domain/transliteration/pali_script_converter.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/script_converter.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/tibetan_phonetics.dart';
import 'package:pali_script_convertor/pali_script_convertor.dart' as psc;

/// Tibetan transliteration done on the phone.
///
/// - "Roman transliteration": THL Simplified Phonetics — how the verse is
///   chanted (bö kyong lha sung). Wylie spelling is only an internal step
///   (the phonetics engine reads the EWTS parse).
/// - every other script: the phonetics re-scripted letter by letter with
///   `pali_script_convertor`, Roman as the source, so Devanagari, Sinhala,
///   Thai… readers can chant from their own script.
///
/// The Tibetan script itself is listed so the picker can name the text as
/// written (བོད་ཡིག); converting to it is a no-op.
class TibetanScriptConverter extends ScriptConverter {
  static const String tibetanScriptId = 'tibetan';
  static const String phoneticScriptId = 'phonetic';

  /// Ids of the scripts reached through the phonetics: `phonetic:si`,
  /// `phonetic:hi`…
  static const String rescriptPrefix = 'phonetic:';

  @override
  String get languageCode => 'bo';

  @override
  List<TransliterationScript> get scripts => _scripts;

  @override
  String convert(String text, String toScriptId) {
    if (toScriptId == tibetanScriptId) return text;
    if (toScriptId == phoneticScriptId) return TibetanPhonetics.transcribe(text);
    if (toScriptId.startsWith(rescriptPrefix)) {
      final target = toScriptId.substring(rescriptPrefix.length);
      final scripted = psc.convertPali(
        rescriptInput(TibetanPhonetics.transcribe(text)),
        target,
        psc.Scripts.ro,
      );
      return _restoreSh(PaliScriptConverter.polish(scripted, target), target);
    }
    throw ArgumentError('Unsupported script id: $toScriptId');
  }

  /// Roman text prepared for the Pali script tables: `_` back to a space;
  /// `[…]` brackets, a-chung apostrophes and stack marks dropped, since none
  /// of them are letters the tables know; ö ü é folded to o u e; and
  /// digraphs rewritten as the Pali letters the tables expect, so ང is one
  /// letter (ṅ) rather than n + g, and ཙ ཚ ཛ take the Indic letters Tibetan
  /// script itself uses for them (c, ch, j). z and zh have no Indic letter
  /// and fall to s and sh; sh then gets each script's ś letter back in
  /// [_restoreSh], since the Pali tables carry ś only for Devanagari and
  /// Sinhala and drop it everywhere else.
  static String rescriptInput(String roman) {
    var s = roman.replaceAll('_', ' ').replaceAll(RegExp(r"[\[\]'+.]"), '');
    for (final (from, to) in _romanToPali) {
      s = s.replaceAll(from, to);
    }
    return s;
  }

  /// Longest first, so "tsh" is not read as "ts" + "h".
  static const List<(String, String)> _romanToPali = [
    ('ö', 'o'),
    ('ü', 'u'),
    ('é', 'e'),
    ('tsh', 'ch'),
    ('ts', 'c'),
    ('dz', 'j'),
    ('ng', 'ṅ'),
    ('ny', 'ñ'),
    ('zh', 'sh'),
    ('z', 's'),
    ('w', 'v'),
  ];

  /// ཤ and ཞ (sh, zh) reach the scripts as s + h — स्ह, สฺห… — because the
  /// Pali tables have no ś there. Every script has its own letter for it.
  static String _restoreSh(String text, String scriptId) {
    final pairs = _shLetters[scriptId];
    if (pairs == null) return text;
    var out = text;
    for (final (from, to) in pairs) {
      out = out.replaceAll(from, to);
    }
    return out;
  }

  /// Thai writes เ and โ before the consonant, so the cluster can be split
  /// by a vowel; Myanmar's h is already the medial ှ after the package's
  /// own clean-up.
  static const Map<String, List<(String, String)>> _shLetters = {
    psc.Scripts.hi: [('स्ह', 'श')],
    psc.Scripts.si: [('ස්හ', 'ශ')],
    psc.Scripts.thai: [('สฺห', 'ศ'), ('สฺเห', 'เศ'), ('สฺโห', 'โศ')],
    psc.Scripts.my: [('သှ', 'ၐ'), ('သ္ဟ', 'ၐ')],
    psc.Scripts.km: [('ស្ហ', 'ឝ')],
    psc.Scripts.beng: [('স্হ', 'শ')],
    psc.Scripts.gurm: [('ਸ੍ਹ', 'ਸ਼')],
    psc.Scripts.guja: [('સ્હ', 'શ')],
    psc.Scripts.telu: [('స్హ', 'శ')],
    psc.Scripts.kann: [('ಸ್ಹ', 'ಶ')],
    psc.Scripts.mala: [('സ്ഹ', 'ശ')],
    psc.Scripts.cyrl: [('сх', 'ш')],
  };

  static final List<TransliterationScript> _scripts = [
    const TransliterationScript(
      id: tibetanScriptId,
      name: 'Tibetan',
      nativeName: 'བོད་ཡིག',
      // Letters, vowel signs and subjoined letters; not digits or punctuation.
      codePointRanges: [
        [0x0F40, 0x0FBC],
      ],
    ),
    const TransliterationScript(
      id: phoneticScriptId,
      name: 'Roman',
      nativeName: 'Roman',
      roman: true,
      codePointRanges: [
        [0x41, 0x5A],
        [0x61, 0x7A],
      ],
      // Latin output; the Tibetan content font is for Uchen only.
      fontLanguage: 'en',
    ),
    // Roman is covered above, and mapping back into Tibetan letters through
    // Pali tables would only garble it.
    for (final script in PaliScriptConverter.paliScripts)
      if (script.id != psc.Scripts.ro && script.id != psc.Scripts.tibt)
        TransliterationScript(
          id: '$rescriptPrefix${script.id}',
          name: script.name,
          nativeName: script.nativeName,
          codePointRanges: script.codePointRanges,
          fontLanguage: 'en',
        ),
  ];
}
