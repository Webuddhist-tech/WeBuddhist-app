import 'package:flutter_pecha/features/reader/domain/transliteration/ewts/ewts_converter.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/ewts/ewts_tables.dart';

/// Tibetan Unicode → THL Simplified Phonetics, syllable by syllable.
///
/// The scheme English-language dharma books use (Trashi, Tendzin, Chöpel,
/// Püntsok). Tone is not marked; aspiration is kept only for kh. Rules are
/// applied per syllable — there is no word segmentation — plus the two
/// cross-syllable habits people notice most: the nasal before an a-chung
/// prefix (mkha' 'gro → khan dro) and ba/bo said wa/wo after another
/// syllable (zla ba → da wa).
///
/// Sanskrit stacks (mantras) are read letter by letter with their marks:
/// ཨོཾ་མ་ཎི་པདྨེ་ཧཱུྃ → om ma ni padme hung.
class TibetanPhonetics {
  TibetanPhonetics._();

  static final EwtsConverter _ewts = EwtsConverter();

  static String transcribe(String text) {
    final units = _ewts.analyze(text);
    final out = <String>[];
    // Index in [out] of the previous syllable, for the cross-syllable rules.
    int? previousSyllable;
    var previousOpen = false;
    var initial = true;
    for (final unit in units) {
      final syllable = unit.syllable;
      if (syllable == null) {
        final other = unit.other!.replaceAll('_', ' ');
        out.add(other);
        // Punctuation other than the tsheg starts a new word.
        if (other.trim().isNotEmpty) initial = true;
        continue;
      }
      final rendered = _syllable(syllable, initial: initial);
      // mkha' 'gro → khan dro: an a-chung prefix before a voiced root
      // nasalises the open syllable before it (not before 'ph, 'kh, 'ch…).
      final first = syllable.stacks.first;
      final rootLetters = syllable.stacks[syllable.rootIndex].letters;
      if (previousSyllable != null &&
          previousOpen &&
          first.prefix &&
          first.letters.isNotEmpty &&
          first.letters.first == "'" &&
          rootLetters.isNotEmpty &&
          _nasalisingRoots.contains(rootLetters.first)) {
        out[previousSyllable] = '${out[previousSyllable]}n';
      }
      previousSyllable = out.length;
      previousOpen = rendered.open;
      initial = false;
      out.add(rendered.text);
    }
    return out.join();
  }

  static _Rendered _syllable(EwtsSyllable syllable, {required bool initial}) {
    final stacks = syllable.stacks;
    final root = syllable.rootIndex;
    final rootStack = stacks[root];
    final prefixLetter =
        root > 0 && stacks[0].prefix && stacks[0].letters.isNotEmpty
            ? stacks[0].letters.first
            : null;

    // Suffixes first: they colour the vowel and tell whether the syllable
    // is closed, which the onset rule for b needs.
    var vowel = _vowel(rootStack.vowels);
    var coda = '';
    final tail = StringBuffer();
    for (var i = root + 1; i < stacks.length; i++) {
      final st = stacks[i];
      if (st.suff2 || st.letters.isEmpty) continue;
      final letter = st.letters.first;
      if (st.suffix) {
        if (_umlautSuffixes.contains(letter)) vowel = _umlaut[vowel] ?? vowel;
        coda = _coda[letter] ?? '';
        continue;
      }
      if (letter == "'" && st.letters.length == 1 && st.vowels.isNotEmpty) {
        // pa'i → pe, mo'i → mö, de'o → deo
        final joined = vowel + _vowel(st.vowels);
        vowel = _particle[joined] ?? joined;
        continue;
      }
      // Sanskrit: pad+me → padme
      final v = _vowel(st.vowels);
      tail.write(st.isNative ? _onset(st.letters, null, v, initial: false, closed: true) : _sanskrit(st.letters));
      tail.write(v);
      tail.write(_finals(st.finals));
    }

    final closed = coda.isNotEmpty || rootStack.finals.isNotEmpty || tail.isNotEmpty;
    final buf = StringBuffer();
    buf.write(
      rootStack.isNative
          ? _onset(rootStack.letters, prefixLetter, vowel, initial: initial, closed: closed)
          : _sanskrit(rootStack.letters),
    );
    buf.write(vowel);
    buf.write(_finals(rootStack.finals));
    buf.write(coda);
    buf.write(tail);
    return _Rendered(buf.toString(), open: !closed);
  }

  /// Onset of a native stack: superscript dropped, subjoined letters
  /// merged the way they are said.
  static String _onset(
    List<String> letters,
    String? prefix,
    String vowel, {
    required bool initial,
    required bool closed,
  }) {
    if (letters.isEmpty) return '';
    var ls = letters;
    var superscript = false;
    if (ls.length > 1 &&
        const {'r', 'l', 's'}.contains(ls.first) &&
        (EwtsTables.superscripts[ls.first]?.contains(ls.sublist(1).join('+')) ??
            false)) {
      if (ls.first == 'l' && ls.length == 2 && ls[1] == 'h') return 'lh';
      ls = ls.sublist(1);
      superscript = true;
    }
    final root = ls.first;
    final sub = ls.length > 1 ? ls[1] : null;
    switch (root) {
      case 'k':
        return switch (sub) { 'y' => 'ky', 'r' => 'tr', 'l' => 'l', _ => 'k' };
      case 'kh':
        return switch (sub) { 'y' => 'khy', 'r' => 'tr', _ => 'kh' };
      case 'g':
        return switch (sub) { 'y' => 'gy', 'r' => 'dr', 'l' => 'l', _ => 'g' };
      case 'c':
      case 'ch':
        return 'ch';
      case 't':
      case 'th':
        return sub == 'r' ? 'tr' : 't';
      case 'd':
        return sub == 'r' ? 'dr' : 'd';
      case 'p':
      case 'ph':
        return switch (sub) { 'y' => 'ch', 'r' => 'tr', _ => 'p' };
      case 'b':
        if (sub == 'y') return prefix == 'd' ? 'y' : 'j';
        if (sub == 'r') return 'dr';
        if (sub == 'l') return 'l';
        // dbang → wang, dbu → u
        if (prefix == 'd' && !superscript) return vowel == 'u' ? '' : 'w';
        // zla ba → da wa: a bare open ba/bo after another syllable
        if (!initial &&
            !superscript &&
            prefix == null &&
            !closed &&
            (vowel == 'a' || vowel == 'o')) {
          return 'w';
        }
        return 'b';
      case 'm':
        return sub == 'y' ? 'ny' : 'm';
      case 'ts':
      case 'tsh':
        return 'ts';
      case 'z':
        return sub == 'l' ? 'd' : 'z';
      case 'r':
        return sub == 'l' ? 'l' : 'r';
      case 's':
        return switch (sub) { 'r' => 's', 'l' => 'l', _ => 's' };
      case 'h':
        return sub == 'r' ? 'hr' : 'h';
      case "'":
      case 'a':
        return '';
      default:
        // ng ny j n w zh y l sh dz: said as written; Sanskrit capitals
        // (N, T, Sh…) lowered
        return _sanskritLetter[root] ?? root;
    }
  }

  /// Sanskrit stacks, letter by letter: k+Sh → ksh, d+h → dh.
  static String _sanskrit(List<String> letters) =>
      letters.map((l) => _sanskritLetter[l] ?? l).join().replaceAll('+', '');

  static String _vowel(List<String> vowels) {
    if (vowels.isEmpty) return 'a';
    return vowels.map((v) => _vowelSign[v] ?? v).join();
  }

  static String _finals(List<String> finals) {
    final buf = StringBuffer();
    for (final f in finals) {
      switch (f) {
        case 'M':
          buf.write('m');
        case '~M':
        case '~M`':
          buf.write('ng');
        case 'H':
          buf.write('h');
        default:
          break;
      }
    }
    return buf.toString();
  }

  /// Roots that take a nasal from a preceding a-chung prefix: 'g 'j 'd 'b
  /// 'dz and their stacks.
  static const Set<String> _nasalisingRoots = {'g', 'j', 'd', 'b', 'dz'};

  static const Set<String> _umlautSuffixes = {'d', 's', 'n', 'l'};

  static const Map<String, String> _umlaut = {'a': 'e', 'o': 'ö', 'u': 'ü'};

  /// Suffix letters as said: g→k, b→p; d s ' and the second suffix are
  /// silent (they only colour the vowel).
  static const Map<String, String> _coda = {
    'g': 'k',
    'ng': 'ng',
    'd': '',
    'n': 'n',
    'b': 'p',
    'm': 'm',
    "'": '',
    'r': 'r',
    'l': 'l',
    's': '',
    'N': 'n',
    'T': 't',
    '-n': 'n',
    '-t': 't',
  };

  /// Vowel + a-chung particle: pa'i → pe, mo'i → mö, bu'i → bü.
  static const Map<String, String> _particle = {
    'ai': 'e',
    'oi': 'ö',
    'ui': 'ü',
    'ei': 'e',
    'ii': 'i',
  };

  static const Map<String, String> _vowelSign = {
    'A': 'a',
    'i': 'i',
    'I': 'i',
    '-i': 'i',
    '-I': 'i',
    'u': 'u',
    'U': 'u',
    'e': 'e',
    'o': 'o',
    'ai': 'ai',
    'au': 'au',
  };

  static const Map<String, String> _sanskritLetter = {
    'T': 't',
    'Th': 't',
    'D': 'd',
    'D+h': 'dh',
    'N': 'n',
    'Sh': 'sh',
    'k+Sh': 'ksh',
    'g+h': 'gh',
    'd+h': 'dh',
    'b+h': 'bh',
    'dz+h': 'dzh',
    'R': 'r',
    'W': 'w',
    'Y': 'y',
    'a': '',
    "'": '',
  };
}

class _Rendered {
  const _Rendered(this.text, {required this.open});

  final String text;

  /// Ends in a vowel, so a following a-chung prefix can nasalise it.
  final bool open;
}
