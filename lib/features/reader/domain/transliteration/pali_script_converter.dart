import 'package:flutter_pecha/features/reader/domain/transliteration/script_converter.dart';
import 'package:pali_script_convertor/pali_script_convertor.dart' as psc;

/// Pali transliteration backed by `pali_script_convertor` (a port of Path
/// Nirvana's converter). Pali texts arrive from the API in Devanagari or
/// Roman; the package detects the source script per run of characters.
///
/// Not offered: Lao and Tai Tham (their conversion tests are disabled
/// upstream) and Assamese (shares Bengali's table in this port, so it would
/// duplicate that row).
class PaliScriptConverter extends ScriptConverter {
  @override
  String get languageCode => 'pi';

  @override
  List<TransliterationScript> get scripts => paliScripts;

  @override
  String convert(String text, String toScriptId) =>
      psc.convertPali(text, toScriptId);

  /// The package's scripts, with picker labels. Also reused by
  /// [TibetanScriptConverter] to re-script Wylie output.
  static const List<TransliterationScript> paliScripts = [
    TransliterationScript(
      id: psc.Scripts.ro,
      name: 'Roman transliteration',
      nativeName: 'Roman transliteration',
      roman: true,
      // Basic Latin letters, Latin-1 / Extended-A, Latin Extended Additional.
      codePointRanges: [
        [0x41, 0x5A],
        [0x61, 0x7A],
        [0xC0, 0x17F],
        [0x1E00, 0x1EFF],
      ],
    ),
    TransliterationScript(
      id: psc.Scripts.hi,
      name: 'Devanagari',
      nativeName: 'देवनागरी',
      codePointRanges: [
        [0x0900, 0x097F],
      ],
    ),
    TransliterationScript(
      id: psc.Scripts.si,
      name: 'Sinhala',
      nativeName: 'සිංහල',
      codePointRanges: [
        [0x0D80, 0x0DFF],
      ],
    ),
    TransliterationScript(
      id: psc.Scripts.thai,
      name: 'Thai',
      nativeName: 'ไทย',
      codePointRanges: [
        [0x0E00, 0x0E7F],
      ],
    ),
    TransliterationScript(
      id: psc.Scripts.my,
      name: 'Myanmar',
      nativeName: 'မြန်မာ',
      codePointRanges: [
        [0x1000, 0x107F],
      ],
    ),
    TransliterationScript(
      id: psc.Scripts.km,
      name: 'Khmer',
      nativeName: 'ខ្មែរ',
      codePointRanges: [
        [0x1780, 0x17FF],
      ],
    ),
    TransliterationScript(
      id: psc.Scripts.beng,
      name: 'Bengali',
      nativeName: 'বাংলা',
      codePointRanges: [
        [0x0980, 0x09FF],
      ],
    ),
    TransliterationScript(
      id: psc.Scripts.gurm,
      name: 'Gurmukhi',
      nativeName: 'ਗੁਰਮੁਖੀ',
      codePointRanges: [
        [0x0A00, 0x0A7F],
      ],
    ),
    TransliterationScript(
      id: psc.Scripts.guja,
      name: 'Gujarati',
      nativeName: 'ગુજરાતી',
      codePointRanges: [
        [0x0A80, 0x0AFF],
      ],
    ),
    TransliterationScript(
      id: psc.Scripts.telu,
      name: 'Telugu',
      nativeName: 'తెలుగు',
      codePointRanges: [
        [0x0C00, 0x0C7F],
      ],
    ),
    TransliterationScript(
      id: psc.Scripts.kann,
      name: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
      codePointRanges: [
        [0x0C80, 0x0CFF],
      ],
    ),
    TransliterationScript(
      id: psc.Scripts.mala,
      name: 'Malayalam',
      nativeName: 'മലയാളം',
      codePointRanges: [
        [0x0D00, 0x0D7F],
      ],
    ),
    TransliterationScript(
      id: psc.Scripts.tibt,
      name: 'Tibetan',
      nativeName: 'བོད་ཡིག',
      codePointRanges: [
        [0x0F00, 0x0FFF],
      ],
      fontLanguage: 'bo',
    ),
    TransliterationScript(
      id: psc.Scripts.cyrl,
      name: 'Cyrillic',
      nativeName: 'Кириллица',
      codePointRanges: [
        [0x0400, 0x04FF],
      ],
    ),
    TransliterationScript(
      id: psc.Scripts.brah,
      name: 'Brahmi',
      nativeName: 'Brāhmī',
      codePointRanges: [
        [0x11000, 0x1107F],
      ],
    ),
  ];
}
