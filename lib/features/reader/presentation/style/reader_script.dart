/// The writing system of a line on the reader page. Sizes and line heights
/// are looked up by it, so a Tibetan line and an English line at the same
/// size step look the same size on screen.
enum ReaderScript {
  latin(1.4, 1.0),
  tibetan(1.9, 1.5),
  chinese(1.6, 1.05),
  devanagari(1.6, 1.0),
  cyrillic(1.4, 1.0);

  const ReaderScript(this.lineHeightRatio, this.interfaceScale);

  /// Line height as a multiple of the font size, at Normal spacing.
  final double lineHeightRatio;

  /// How much bigger interface text written in this script is than Latin at
  /// the same nominal size, so labels look the same size on screen.
  final double interfaceScale;

  /// How many letters decide a line's script; the rest are not read.
  static const int _sampleLetters = 40;

  /// The script most of [text]'s letters are written in, reading past HTML
  /// tags and entities. Falls back to [language]'s script when [text] has
  /// no letters, and to Latin when there is no language either.
  ///
  /// The text decides rather than the language: a Tibetan text shown in
  /// Devanagari transliteration is a Devanagari line.
  static ReaderScript of(String? text, {String? language}) {
    final counts = <ReaderScript, int>{};
    var seen = 0;
    var inTag = false;
    var inEntity = false;
    for (final rune in (text ?? '').runes) {
      if (inTag) {
        if (rune == 0x3E) inTag = false; // >
        continue;
      }
      if (inEntity) {
        if (rune == 0x3B || rune == 0x20) inEntity = false; // ; or space
        continue;
      }
      if (rune == 0x3C) {
        inTag = true; // <
        continue;
      }
      if (rune == 0x26) {
        inEntity = true; // &
        continue;
      }
      final script = _scriptOfLetter(rune);
      if (script == null) continue;
      counts[script] = (counts[script] ?? 0) + 1;
      if (++seen >= _sampleLetters) break;
    }
    if (counts.isEmpty) return ofLanguage(language);
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  /// The script [language] is normally written in.
  static ReaderScript ofLanguage(String? language) {
    final code = (language ?? '').trim().toLowerCase().split(RegExp('[-_]'));
    return switch (code.first) {
      'bo' || 'dz' => ReaderScript.tibetan,
      'zh' || 'lzh' => ReaderScript.chinese,
      'hi' || 'ne' || 'mr' || 'sa' => ReaderScript.devanagari,
      'mn' || 'ru' || 'uk' || 'bg' => ReaderScript.cyrillic,
      _ => ReaderScript.latin,
    };
  }

  static ReaderScript? _scriptOfLetter(int rune) {
    if (rune >= 0x0F40 && rune <= 0x0FBC) return ReaderScript.tibetan;
    if ((rune >= 0x4E00 && rune <= 0x9FFF) ||
        (rune >= 0x3400 && rune <= 0x4DBF) ||
        (rune >= 0xF900 && rune <= 0xFAFF)) {
      return ReaderScript.chinese;
    }
    if (rune >= 0x0900 && rune <= 0x097F) return ReaderScript.devanagari;
    if (rune >= 0x0400 && rune <= 0x04FF) return ReaderScript.cyrillic;
    if ((rune >= 0x41 && rune <= 0x5A) ||
        (rune >= 0x61 && rune <= 0x7A) ||
        (rune >= 0xC0 && rune <= 0x24F) ||
        (rune >= 0x1E00 && rune <= 0x1EFF)) {
      return ReaderScript.latin;
    }
    return null;
  }
}
