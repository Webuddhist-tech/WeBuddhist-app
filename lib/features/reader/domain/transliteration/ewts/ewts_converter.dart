import 'package:flutter_pecha/features/reader/domain/transliteration/ewts/ewts_tables.dart';

/// Tibetan Unicode ↔ Extended Wylie (EWTS).
///
/// Ported from pyewts (github.com/Webuddhist-tech/pyewts), the Python port
/// of BDRC's ewts-converter. Apache License 2.0. Copyright (C) 2010 Roger
/// Espel Llima; (c) 2011–2017 Buddhist Digital Resource Center.
///
/// Where pyewts and BDRC's jsewts disagree, this follows jsewts, because the
/// conversion corpus in `test/…/fixtures/ewts_test_cases.txt` was written
/// against it: the sloppy-Wylie normalisation table, nested `[comments]`,
/// and the `a+a` stack. Only the EWTS flavour is ported (no DTS / ALALC /
/// ACIP input).
class EwtsConverter {
  EwtsConverter({this.check = true, this.checkStrict = true}) {
    if (checkStrict && !check) {
      throw ArgumentError('checkStrict requires check.');
    }
  }

  /// Warn about illegal consonant sequences when converting to Unicode.
  final bool check;

  /// Stricter checking: examine whole stacks, not just adjacent letters.
  final bool checkStrict;

  // ---------------------------------------------------------------------
  // Wylie → Unicode
  // ---------------------------------------------------------------------

  /// Common sloppiness in typed Wylie: curly apostrophes, spaces where a
  /// literal space (`_`) is meant, upper-case letters that have no meaning.
  static String normalizeSloppyWylie(String input) {
    var str = input.replaceAll(RegExp('[ʼʹ‘’ʾ]'), "'");
    str = str.replaceAllMapped(RegExp(r' ([(0-9])'), (m) => '_${m[1]}');
    str = str.replaceAllMapped(RegExp(r'([_)/:]) '), (m) => '${m[1]}_');
    str = str
        .replaceAll('G', 'g')
        .replaceAll('C', 'c')
        .replaceAll('B', 'b')
        .replaceAll('L', 'l')
        .replaceAll('P', 'p')
        .replaceAll('Z', 'z');
    return str.replaceFirst(RegExp(r'^\s+'), '');
  }

  /// Converts Wylie to Tibetan Unicode. Warnings, when a list is given, are
  /// prefixed with the line number.
  String toUnicode(String input, {List<String>? warns, bool sloppy = true}) {
    final str = sloppy ? normalizeSloppyWylie(input) : input;
    final tokens = _splitIntoTokens(str);
    final out = StringBuffer();
    var line = 1;
    var units = 0;
    var i = 0;
    final n = tokens.length;

    iter:
    while (i < n) {
      var t = tokens[i];

      // [non-tibetan text] : pass through, nesting brackets
      if (t == '[') {
        var nesting = 1;
        i++;
        while (i < n) {
          t = tokens[i++];
          if (t == '[') nesting++;
          if (t == ']') nesting--;
          if (nesting == 0) continue iter;
          if (t.startsWith(r'\u') || t.startsWith(r'\U')) {
            final o = _unicodeEscape(warns, line, t);
            if (o != null) {
              out.write(o);
              continue;
            }
          }
          out.write(t.startsWith(r'\') ? t.substring(1) : t);
        }
        _warnl(warns, line, 'Unfinished [non-Wylie stuff].');
        break;
      }

      // punctuation, numbers, etc
      final o = EwtsTables.other[t];
      if (o != null) {
        out.write(o);
        i++;
        units++;
        if (t == ' ' && sloppy) {
          while (i < n && tokens[i] == ' ') {
            i++;
          }
        }
        continue;
      }

      // vowels & consonants: one tsekbar up to a tsek or punctuation
      if (EwtsTables.vowel.containsKey(t) ||
          EwtsTables.consonant.containsKey(t)) {
        final tb = _toUnicodeOneTsekbar(tokens, i);
        final word = tokens.sublist(i, i + tb.tokensUsed).join();
        out.write(tb.uniString);
        i += tb.tokensUsed;
        units++;
        for (final w in tb.warns) {
          _warnl(warns, line, '"$word": $w');
        }
        continue;
      }

      // BOM and zero-width space
      if (t == '﻿' || t == '​') {
        i++;
        continue;
      }

      // \uxxxx and \Uxxxxxxxx escapes
      if (t.startsWith(r'\u') || t.startsWith(r'\U')) {
        final o = _unicodeEscape(warns, line, t);
        if (o != null) {
          i++;
          out.write(o);
          continue;
        }
      }

      // backslashed characters
      if (t.startsWith(r'\')) {
        out.write(t.substring(1));
        i++;
        continue;
      }

      // newlines; spaces after them are eaten in sloppy mode
      if (t == '\r\n' || t == '\n' || t == '\r') {
        line++;
        out.write(t);
        i++;
        if (sloppy) {
          while (i < n && tokens[i] == ' ') {
            i++;
          }
        }
        continue;
      }

      // special characters and stray letters out of context
      final c = t.codeUnitAt(0);
      if (EwtsTables.special.contains(t) ||
          (c >= 0x61 && c <= 0x7A) ||
          (c >= 0x41 && c <= 0x5A)) {
        _warnl(warns, line, 'Unexpected character "$t".');
      }
      out.write(t);
      i++;
    }

    if (units == 0) _warn(warns, 'No Tibetan characters found!');
    return out.toString();
  }

  static int _maxTokenLen(String str, int i, int len, int max) {
    var l = len;
    while (l > 1) {
      if (i <= max - l && EwtsTables.tokens.contains(str.substring(i, i + l))) {
        return l;
      }
      l--;
    }
    return 0;
  }

  static List<String> _splitIntoTokens(String str) {
    final tokens = <String>[];
    var i = 0;
    final max = str.length;
    while (i < max) {
      final c = str[i];
      final len = EwtsTables.tokensStart[c];
      if (len != null) {
        final tokenLen = _maxTokenLen(str, i, len, max);
        if (tokenLen > 0) {
          tokens.add(str.substring(i, i + tokenLen));
          i += tokenLen;
          continue;
        }
      }
      if (c == r'\' && i <= max - 2) {
        if (str[i + 1] == 'u' && i <= max - 6) {
          tokens.add(str.substring(i, i + 6));
          i += 6;
        } else if (str[i + 1] == 'U' && i <= max - 10) {
          tokens.add(str.substring(i, i + 10));
          i += 10;
        } else {
          tokens.add(str.substring(i, i + 2));
          i += 2;
        }
        continue;
      }
      tokens.add(c);
      i++;
    }
    return tokens;
  }

  static bool _validHex(String hex) =>
      RegExp(r'^[a-f0-9]+$').hasMatch(hex);

  String? _unicodeEscape(List<String>? warns, int line, String t) {
    final hex = t.substring(2);
    if (hex.isEmpty) return null;
    if (!_validHex(hex)) {
      _warnl(warns, line, '"$t": invalid hex code.');
      return '';
    }
    return String.fromCharCode(int.parse(hex, radix: 16));
  }

  static bool _superscript(String sup, String below) =>
      EwtsTables.superscripts[sup]?.contains(below) ?? false;

  static bool _subscript(String sub, String above) =>
      EwtsTables.subscripts[sub]?.contains(above) ?? false;

  static bool _prefix(String pref, String after) =>
      EwtsTables.prefixes[pref]?.contains(after) ?? false;

  static bool _suff2(String suff, String? before) =>
      before != null && (EwtsTables.suff2[suff]?.contains(before) ?? false);

  /// Consonants from [i] onwards, up to the next vowel or punctuation,
  /// joined by "+". Skips the caret.
  static String _consonantString(List<String> tokens, int start) {
    final out = <String>[];
    var i = start;
    while (i < tokens.length) {
      final t = tokens[i++];
      if (t == '+' || t == '^') continue;
      if (!EwtsTables.consonant.containsKey(t)) break;
      out.add(t);
    }
    return out.join('+');
  }

  static String _consonantStringBackwards(
    List<String> tokens,
    int start,
    int origI,
  ) {
    final out = <String>[];
    var i = start;
    while (i >= origI && i < tokens.length) {
      final t = tokens[i--];
      if (t == '+' || t == '^') continue;
      if (!EwtsTables.consonant.containsKey(t)) break;
      out.insert(0, t);
    }
    return out.join('+');
  }

  _WylieStack _toUnicodeOneStack(List<String> tokens, int start) {
    var i = start;
    final n = tokens.length;
    final out = StringBuffer();
    final warns = <String>[];
    var consonants = 0;
    String? vowelFound;
    String? vowelSign;
    String? singleConsonant;
    var plus = false;
    var caret = 0;
    final finalFound = <String, String>{};

    String? tok(int k) => k < n ? tokens[k] : null;

    var t = tok(i);
    final t2 = tok(i + 1);

    // superscript
    if (t != null &&
        t2 != null &&
        EwtsTables.superscripts.containsKey(t) &&
        _superscript(t, t2)) {
      if (checkStrict) {
        var next = _consonantString(tokens, i + 1);
        if (!_superscript(t, next)) {
          next = next.replaceAll('+', '');
          warns.add(
            'Superscript "$t" does not occur above combination "$next".',
          );
        }
      }
      out.write(EwtsTables.consonant[t]);
      consonants++;
      i++;
      while (tok(i) == '^') {
        caret++;
        i++;
      }
    }

    main:
    while (true) {
      t = tok(i);
      if (t != null &&
          (EwtsTables.consonant.containsKey(t) ||
              (out.isNotEmpty && EwtsTables.subjoined.containsKey(t)))) {
        out.write(
          out.isNotEmpty
              ? (EwtsTables.subjoined[t] ?? EwtsTables.consonant[t])
              : EwtsTables.consonant[t],
        );
        i++;
        if (t == 'a') {
          vowelFound = 'a';
        } else {
          consonants++;
          singleConsonant = t;
        }
        while (tok(i) == '^') {
          caret++;
          i++;
        }

        // subscripts, up to two (e.g. "grwa")
        for (var z = 0; z < 2; z++) {
          final s = tok(i);
          if (s == null || !EwtsTables.subscripts.containsKey(s)) break;
          if (s == 'l' && consonants > 1) break;
          if (checkStrict && !plus) {
            var prev = _consonantStringBackwards(tokens, i - 1, start);
            if (!_subscript(s, prev)) {
              prev = prev.replaceAll('+', '');
              warns.add('Subjoined "$s" not expected after "$prev".');
            }
          } else if (check) {
            if (!_subscript(s, t!) && !(z == 1 && s == 'w' && t == 'y')) {
              warns.add('Subjoined "$s"not expected after "$t".');
            }
          }
          out.write(EwtsTables.subjoined[s]);
          i++;
          consonants++;
          while (tok(i) == '^') {
            caret++;
            i++;
          }
          t = s;
        }
      }

      if (caret > 0) {
        if (caret > 1) {
          warns.add('Cannot have more than one "^" applied to the same stack.');
        }
        finalFound['^'] = '^';
        out.write(EwtsTables.finalUni['^']);
        caret = 0;
      }

      t = tok(i);
      if (t != null && EwtsTables.vowel.containsKey(t)) {
        if (out.isEmpty) out.write(EwtsTables.vowel['a']);
        if (t != 'a') out.write(EwtsTables.vowel[t]);
        i++;
        vowelFound = t;
        if (t != 'a') vowelSign = t;
      }

      t = tok(i);
      if (t == '+') {
        i++;
        plus = true;
        t = tok(i);
        if (t == null ||
            (!EwtsTables.vowel.containsKey(t) &&
                !EwtsTables.subjoined.containsKey(t))) {
          if (check) warns.add('Expected vowel or consonant after "+".');
          break main;
        }
        if (check) {
          if (!EwtsTables.vowel.containsKey(t) && vowelSign != null) {
            warns.add(
              'Cannot subjoin consonant ($t) after vowel ($vowelSign) in same stack.',
            );
          } else if (t == 'a' && vowelSign != null) {
            warns.add(
              'Cannot subjoin a-chen (a) after vowel ($vowelSign) in same stack.',
            );
          }
        }
        continue main;
      }
      break;
    }

    // final signs
    t = tok(i);
    while (t != null && EwtsTables.finalClass.containsKey(t)) {
      final uni = EwtsTables.finalUni[t]!;
      final klass = EwtsTables.finalClass[t]!;
      final found = finalFound[klass];
      if (found != null) {
        if (found == t) {
          warns.add('Cannot have two "$t" applied to the same stack.');
        } else {
          warns.add('Cannot have "$t" and "$found" applied to the same stack.');
        }
      } else {
        finalFound[klass] = t;
        out.write(uni);
      }
      i++;
      singleConsonant = null;
      t = tok(i);
    }

    // a "." (the g.ya separator) just gets eaten
    if (tok(i) == '.') i++;

    // a stack of several consonants without a vowel is a single consonant,
    // unless "+" made the stacking explicit
    if (consonants > 1 && vowelFound == null) {
      if (plus) {
        if (check) {
          warns.add('Stack with multiple consonants should end with vowel.');
        }
      } else {
        i = start + 1;
        consonants = 1;
        singleConsonant = tokens[start];
        out.clear();
        out.write(EwtsTables.consonant[singleConsonant]);
      }
    }
    if (consonants != 1 || plus) singleConsonant = null;

    return _WylieStack(
      uniString: out.toString(),
      tokensUsed: i - start,
      singleConsonant: vowelFound != null ? null : singleConsonant,
      singleConsA: vowelFound == 'a' ? singleConsonant : null,
      warns: warns,
      visarga: finalFound.containsKey('H'),
    );
  }

  _WylieTsekbar _toUnicodeOneTsekbar(List<String> tokens, int start) {
    var i = start;
    final n = tokens.length;
    _WylieStack? stack;
    String? prevCons;
    var visarga = false;
    var checkRoot = true;
    final consonants = <String>[];
    var rootIdx = -1;
    final out = StringBuffer();
    final warns = <String>[];
    var state = _State.prefix;

    String? tok(int k) => k < n ? tokens[k] : null;

    var t = tok(i);
    while (t != null &&
        (EwtsTables.vowel.containsKey(t) ||
            EwtsTables.consonant.containsKey(t)) &&
        !visarga) {
      if (stack != null) prevCons = stack.singleConsonant;
      stack = _toUnicodeOneStack(tokens, i);
      i += stack.tokensUsed;
      t = tok(i);
      out.write(stack.uniString);
      warns.addAll(stack.warns);
      visarga = stack.visarga;
      if (!check) continue;

      final sc = stack.singleConsonant;
      if (state == _State.prefix && sc != null) {
        consonants.add(sc);
        if (EwtsTables.prefixes.containsKey(sc)) {
          var next = checkStrict ? _consonantString(tokens, i) : t;
          if (next != null && !_prefix(sc, next)) {
            next = next.replaceAll('+', '');
            warns.add('Prefix "$sc" does not occur before "$next".');
          }
        } else {
          warns.add('Invalid prefix consonant: "$sc".');
        }
        state = _State.main;
      } else if (sc == null) {
        state = _State.suff1;
        if (rootIdx >= 0) {
          checkRoot = false;
        } else if (stack.singleConsA != null) {
          consonants.add(stack.singleConsA!);
          rootIdx = consonants.length - 1;
        }
      } else if (state == _State.main) {
        warns.add('Expected vowel after "$sc".');
      } else if (state == _State.suff1) {
        consonants.add(sc);
        if (checkStrict && !EwtsTables.suffixes.contains(sc)) {
          warns.add('Invalid suffix consonant: "$sc".');
        }
        state = _State.suff2;
      } else if (state == _State.suff2) {
        consonants.add(sc);
        if (EwtsTables.suff2.containsKey(sc)) {
          if (!_suff2(sc, prevCons)) {
            warns.add('Second suffix "$sc" does not occur after "$prevCons".');
          }
        } else if (!EwtsTables.affixedSuff2.contains(sc) || prevCons != "'") {
          warns.add('Invalid 2nd suffix consonant: "$sc".');
        }
        state = _State.none;
      } else if (state == _State.none) {
        warns.add('Cannot have another consonant "$sc" after 2nd suffix.');
      }
    }

    final lastCons = stack?.singleConsonant;
    if (state == _State.main &&
        lastCons != null &&
        EwtsTables.prefixes.containsKey(lastCons)) {
      warns.add('Vowel expected after "$lastCons".');
    }

    if (check && warns.isEmpty && checkRoot && rootIdx >= 0) {
      if (consonants.length == 2 &&
          rootIdx != 0 &&
          _prefix(consonants[0], consonants[1]) &&
          EwtsTables.suffixes.contains(consonants[1])) {
        warns.add(
          'Syllable should probably be "${consonants[0]}a${consonants[1]}".',
        );
      } else if (consonants.length == 3 &&
          EwtsTables.prefixes.containsKey(consonants[0]) &&
          _suff2('s', consonants[1]) &&
          consonants[2] == 's') {
        final cc = consonants
            .join()
            .replaceAll('‘', "'")
            .replaceAll('’', "'");
        final expectKey = EwtsTables.ambiguousKey[cc];
        if (expectKey != null && expectKey != rootIdx) {
          warns.add(
            'Syllable should probably be "${EwtsTables.ambiguousWylie[cc]}".',
          );
        }
      }
    }

    return _WylieTsekbar(
      uniString: out.toString(),
      tokensUsed: i - start,
      warns: warns,
    );
  }

  // ---------------------------------------------------------------------
  // Unicode → Wylie
  // ---------------------------------------------------------------------

  /// Converts Tibetan Unicode to Wylie. With [escape] (the default), text
  /// that is not Tibetan is wrapped in `[…]` and a literal space between
  /// Tibetan runs is written `_`, as EWTS requires; without it, both pass
  /// through.
  String toWylie(String input, {List<String>? warns, bool escape = true}) {
    // deprecated pre-composed Sanskrit vowels (I and U are handled as vowel
    // signs; pyewts also expands them here, jsewts does not)
    final str = _expandPrecomposedVowels(input);
    final out = StringBuffer();
    var line = 1;
    var i = 0;
    final n = str.length;

    while (i < n) {
      final t = str[i];

      if (EwtsTables.tibTop.containsKey(t)) {
        final tb = _toWylieOneTsekbar(str, i);
        out.write(tb.wylie);
        i += tb.tokensUsed;
        for (final w in tb.warns) {
          _warnl(warns, line, w);
        }
        if (!escape) i += _handleSpaces(str, i, out);
        continue;
      }

      // punctuation. Spaces: in escaping mode they stay part of a coming
      // [escaped block] when non-Tibetan follows.
      final o = EwtsTables.tibOther[t];
      if (o != null && (t != ' ' || (escape && !_followedByNonTibetan(str, i)))) {
        out.write(o);
        i++;
        if (!escape) i += _handleSpaces(str, i, out);
        continue;
      }

      if (t == '\r' || t == '\n') {
        line++;
        i++;
        out.write(t);
        if (t == '\r' && i < n && str[i] == '\n') {
          i++;
          out.write('\n');
        }
        continue;
      }

      if (t == '﻿' || t == '​') {
        i++;
        continue;
      }

      if (!escape) {
        out.write(t);
        i++;
        continue;
      }

      // other characters in the Tibetan block: \u0fxx
      if (_inTibetanBlock(t)) {
        final c = _formatHex(t);
        out.write(c);
        i++;
        if (EwtsTables.tibSubjoined.containsKey(t) ||
            EwtsTables.tibVowel.containsKey(t) ||
            EwtsTables.tibFinalWylie.containsKey(t)) {
          _warnl(warns, line, 'Tibetan sign $c needs a top symbol to attach to.');
        }
        continue;
      }

      // anything else goes in [comments], closed at line ends
      out.write('[');
      var u = t;
      while (!EwtsTables.tibTop.containsKey(u) &&
          (!EwtsTables.tibOther.containsKey(u) || u == ' ') &&
          u != '\r' &&
          u != '\n') {
        if (u == '[' || u == ']') {
          out.write(r'\');
          out.write(u);
        } else if (_inTibetanBlock(u)) {
          out.write(_formatHex(u));
        } else {
          out.write(u);
        }
        i++;
        if (i >= n) break;
        u = str[i];
      }
      out.write(']');
    }
    return out.toString();
  }

  static bool _inTibetanBlock(String t) {
    final c = t.codeUnitAt(0);
    return c >= 0x0f00 && c <= 0x0fff;
  }

  static String _formatHex(String t) =>
      '\\u${t.codeUnitAt(0).toRadixString(16).padLeft(4, '0')}';

  /// Spaces between two Tibetan runs in non-escaping mode become `_`.
  /// (pyewts and jsewts compute this but drop the result; BDRC's Java
  /// original writes it, and that is what is done here.)
  static int _handleSpaces(String str, int start, StringBuffer out) {
    var i = start;
    var found = 0;
    while (i < str.length && str[i] == ' ') {
      i++;
      found++;
    }
    if (found == 0 || i == str.length) return 0;
    final t = str[i];
    if (!EwtsTables.tibTop.containsKey(t) &&
        !EwtsTables.tibOther.containsKey(t)) {
      return 0;
    }
    out.write('_' * found);
    return found;
  }

  static bool _followedByNonTibetan(String str, int start) {
    var i = start;
    while (i < str.length && str[i] == ' ') {
      i++;
    }
    if (i == str.length) return false;
    final t = str[i];
    return !EwtsTables.tibTop.containsKey(t) &&
        !EwtsTables.tibOther.containsKey(t) &&
        t != '\r' &&
        t != '\n';
  }

  // ---------------------------------------------------------------------
  // Structural parse (shared with the phonetics engine)
  // ---------------------------------------------------------------------

  /// Splits Tibetan Unicode into syllables (with each stack's letters,
  /// vowels, finals and the prefix / suffix role the Wylie rules assign)
  /// and the text between them, already in Wylie form.
  List<EwtsUnit> analyze(String input) {
    final str = _expandPrecomposedVowels(input);
    final units = <EwtsUnit>[];
    var i = 0;
    final n = str.length;
    while (i < n) {
      final t = str[i];
      if (EwtsTables.tibTop.containsKey(t)) {
        final a = _analyzeTsekbar(str, i);
        units.add(
          EwtsUnit.syllable(
            EwtsSyllable([for (final st in a.stacks) st.toPublic()]),
          ),
        );
        i += a.tokensUsed;
        continue;
      }
      if (t == '﻿' || t == '​') {
        i++;
        continue;
      }
      units.add(EwtsUnit.other(EwtsTables.tibOther[t] ?? t));
      i++;
    }
    return units;
  }

  static String _expandPrecomposedVowels(String input) => input
      .replaceAll('ྲྀ', 'ྲྀ')
      .replaceAll('ཷ', 'ྲཱྀ')
      .replaceAll('ླྀ', 'ླྀ')
      .replaceAll('ཹ', 'ླཱྀ')
      .replaceAll('ཱྀ', 'ཱྀ');

  _ToWylieTsekbar _toWylieOneTsekbar(String str, int start) {
    final a = _analyzeTsekbar(str, start);
    final out = StringBuffer();
    for (final st in a.stacks) {
      out.write(_putStackTogether(st));
    }
    return _ToWylieTsekbar(
      wylie: out.toString(),
      tokensUsed: a.tokensUsed,
      warns: a.warns,
    );
  }

  _TsekbarAnalysis _analyzeTsekbar(String str, int start) {
    var i = start;
    final n = str.length;
    final warns = <String>[];
    final stacks = <_ToWylieStack>[];

    while (true) {
      final st = _toWylieOneStack(str, i);
      stacks.add(st);
      warns.addAll(st.warns);
      i += st.tokensUsed;
      if (st.visarga) break;
      if (i >= n || !EwtsTables.tibTop.containsKey(str[i])) break;
    }

    final last = stacks.length - 1;
    final first = stacks[0];
    if (stacks.length > 1 && first.singleCons != null) {
      final cs = stacks[1].consStr.replaceAll('+w', '');
      if (_prefix(first.singleCons!, cs)) first.prefix = true;
    }
    if (stacks.length > 1 &&
        stacks[last].singleCons != null &&
        EwtsTables.suffixes.contains(stacks[last].singleCons)) {
      stacks[last].suffix = true;
    }
    if (stacks.length > 2 &&
        stacks[last].singleCons != null &&
        stacks[last - 1].singleCons != null &&
        EwtsTables.suffixes.contains(stacks[last - 1].singleCons) &&
        _suff2(stacks[last].singleCons!, stacks[last - 1].singleCons)) {
      stacks[last].suff2 = true;
      stacks[last - 1].suffix = true;
    }
    // "dag", not "dga": a two-letter syllable is root + suffix
    if (stacks.length == 2 && first.prefix && stacks[1].suffix) {
      first.prefix = false;
    }
    // three bare letters that read as prefix + suffix + second suffix
    if (stacks.length == 3 &&
        first.prefix &&
        stacks[1].suffix &&
        stacks[2].suff2) {
      final ztr = stacks.map((s) => s.singleCons!).join();
      var root = EwtsTables.ambiguousKey[ztr];
      if (root == null) {
        warns.add(
          'Ambiguous syllable found: root consonant not known for "$ztr".',
        );
        root = 1;
      }
      stacks[root].prefix = false;
      stacks[root].suffix = false;
      stacks[root + 1].suff2 = false;
    }
    if (first.prefix &&
        EwtsTables.tibStacks.contains(
          '${first.singleCons}+${stacks[1].consStr}',
        )) {
      first.dot = true;
    }

    return _TsekbarAnalysis(stacks: stacks, tokensUsed: i - start, warns: warns);
  }

  _ToWylieStack _toWylieOneStack(String str, int start) {
    var i = start;
    final n = str.length;
    String? ffinal;
    String? vowel;
    final st = _ToWylieStack();

    var t = str[i];
    i++;
    st.top = EwtsTables.tibTop[t];
    if (st.top != null) st.stack.add(st.top!);

    while (i < n) {
      t = str[i];
      final sub = EwtsTables.tibSubjoined[t];
      if (sub != null) {
        i++;
        st.stack.add(sub);
        if (st.finals.isNotEmpty) {
          st.warns.add(
            'Subjoined sign "$sub" found after final sign "$ffinal".',
          );
        } else if (st.vowels.isNotEmpty) {
          st.warns.add('Subjoined sign "$sub" found after vowel sign "$vowel".');
        }
        continue;
      }
      final v = EwtsTables.tibVowel[t];
      if (v != null) {
        i++;
        st.vowels.add(v);
        vowel ??= v;
        if (st.finals.isNotEmpty) {
          st.warns.add('Vowel sign "$v" found after final sign "$ffinal".');
        }
        continue;
      }
      final f = EwtsTables.tibFinalWylie[t];
      if (f != null) {
        i++;
        final klass = EwtsTables.tibFinalClass[t]!;
        if (f == '^') {
          st.caret = true;
        } else {
          if (f == 'H') st.visarga = true;
          st.finals.add(f);
          ffinal ??= f;
          if (st.finalsFound.containsKey(klass)) {
            st.warns.add(
              'Final sign "$f" should not combine with found after final sign "$ffinal".',
            );
          } else {
            st.finalsFound[klass] = f;
          }
        }
        continue;
      }
      break;
    }

    // a-chen carries only its vowel: ཨོཾ is "oM"
    if (st.top == 'a' && st.stack.length == 1 && st.vowels.isNotEmpty) {
      st.stack.removeAt(0);
    }
    // a-chung mark + i/u/-i = long vowel
    if (st.vowels.length > 1 &&
        st.vowels[0] == 'A' &&
        EwtsTables.tibVowelLong.containsKey(st.vowels[1])) {
      final l = EwtsTables.tibVowelLong[st.vowels[1]]!;
      st.vowels.removeAt(0);
      st.vowels.removeAt(0);
      st.vowels.insert(0, l);
    }
    // caret on a lone ph/b: f/v
    if (st.caret && st.stack.length == 1 && EwtsTables.tibCaret.containsKey(st.top)) {
      final l = EwtsTables.tibCaret[st.top]!;
      st.top = l;
      st.stack[0] = l;
      st.caret = false;
    }
    st.consStr = st.stack.join('+');
    if (st.stack.length == 1 &&
        st.stack[0] != 'a' &&
        !st.caret &&
        st.vowels.isEmpty &&
        st.finals.isEmpty) {
      st.singleCons = st.consStr;
    }
    st.tokensUsed = i - start;
    return st;
  }

  static String _putStackTogether(_ToWylieStack st) {
    final out = StringBuffer();
    out.write(
      EwtsTables.tibStacks.contains(st.consStr) ? st.stack.join() : st.consStr,
    );
    if (st.caret) out.write('^');
    if (st.vowels.isNotEmpty) {
      out.write(st.vowels.join('+'));
    } else if (!st.prefix &&
        !st.suffix &&
        !st.suff2 &&
        (st.consStr.isEmpty || !st.consStr.endsWith('a'))) {
      out.write('a');
    }
    out.write(st.finals.join());
    if (st.dot) out.write('.');
    return out.toString();
  }

  // ---------------------------------------------------------------------

  static void _warn(List<String>? warns, String message) {
    warns?.add(message);
  }

  static void _warnl(List<String>? warns, int line, String message) {
    _warn(warns, 'line $line: $message');
  }
}

enum _State { prefix, main, suff1, suff2, none }

class _WylieStack {
  const _WylieStack({
    required this.uniString,
    required this.tokensUsed,
    required this.singleConsonant,
    required this.singleConsA,
    required this.warns,
    required this.visarga,
  });

  final String uniString;
  final int tokensUsed;
  final String? singleConsonant;
  final String? singleConsA;
  final List<String> warns;
  final bool visarga;
}

class _WylieTsekbar {
  const _WylieTsekbar({
    required this.uniString,
    required this.tokensUsed,
    required this.warns,
  });

  final String uniString;
  final int tokensUsed;
  final List<String> warns;
}

class _ToWylieStack {
  String? top;
  final List<String> stack = [];
  bool caret = false;
  final List<String> vowels = [];
  final List<String> finals = [];
  final Map<String, String> finalsFound = {};
  bool visarga = false;
  String consStr = '';
  String? singleCons;
  bool prefix = false;
  bool suffix = false;
  bool suff2 = false;
  bool dot = false;
  int tokensUsed = 0;
  final List<String> warns = [];

  EwtsStack toPublic() => EwtsStack(
    letters: List.unmodifiable(stack),
    vowels: List.unmodifiable(vowels),
    finals: List.unmodifiable(finals),
    caret: caret,
    prefix: prefix,
    suffix: suffix,
    suff2: suff2,
  );
}

class _TsekbarAnalysis {
  const _TsekbarAnalysis({
    required this.stacks,
    required this.tokensUsed,
    required this.warns,
  });

  final List<_ToWylieStack> stacks;
  final int tokensUsed;
  final List<String> warns;
}

/// One consonant stack of a syllable, as the Wylie rules see it.
class EwtsStack {
  const EwtsStack({
    required this.letters,
    required this.vowels,
    required this.finals,
    required this.caret,
    required this.prefix,
    required this.suffix,
    required this.suff2,
  });

  /// Wylie letters top-down, e.g. `[s, k, y]` for སྐྱ; `[a]` for ཨ.
  final List<String> letters;

  /// Wylie vowel signs, e.g. `[o]`; empty means the inherent a.
  final List<String> vowels;

  /// Wylie final signs: `M`, `~M`, `H`, …
  final List<String> finals;
  final bool caret;

  /// Roles assigned by the Wylie rules: a silent prefix letter, a suffix,
  /// or a second suffix. A stack with none of them carries the vowel.
  final bool prefix;
  final bool suffix;
  final bool suff2;

  String get consStr => letters.join('+');

  /// A stack Tibetan writes without "+": single letters and the native
  /// combinations. Anything else is Sanskrit or a typo.
  bool get isNative =>
      letters.length == 1 || EwtsTables.tibStacks.contains(consStr);

  bool get isRoot => !prefix && !suffix && !suff2;
}

/// One tsekbar: the stacks between two tshegs.
class EwtsSyllable {
  const EwtsSyllable(this.stacks);

  final List<EwtsStack> stacks;

  /// Index of the stack that carries the vowel.
  int get rootIndex {
    final i = stacks.indexWhere((s) => s.isRoot);
    return i < 0 ? 0 : i;
  }
}

/// A syllable, or a run of text between syllables (tsheg → " ", shad →
/// "/", digits, or any non-Tibetan character as is).
class EwtsUnit {
  const EwtsUnit.syllable(EwtsSyllable this.syllable) : other = null;
  const EwtsUnit.other(String this.other) : syllable = null;

  final EwtsSyllable? syllable;
  final String? other;
}

class _ToWylieTsekbar {
  const _ToWylieTsekbar({
    required this.wylie,
    required this.tokensUsed,
    required this.warns,
  });

  final String wylie;
  final int tokensUsed;
  final List<String> warns;
}
