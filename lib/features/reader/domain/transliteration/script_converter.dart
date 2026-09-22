/// A script a [ScriptConverter] can write a text in.
class TransliterationScript {
  const TransliterationScript({
    required this.id,
    required this.name,
    required this.nativeName,
    required this.codePointRanges,
    this.fontLanguage,
    this.roman = false,
  });

  /// Converter-specific script id. Not an ISO language code — several ids
  /// collide with unrelated languages (`ka`, `be`, `cy`…), so never feed one
  /// to `getLanguageName`.
  final String id;

  /// English script name, e.g. "Sinhala".
  final String name;

  /// The script's own name written in that script, e.g. "සිංහල".
  final String nativeName;

  /// Inclusive Unicode code point ranges used to recognise text written in
  /// this script. Letters only — digits and punctuation must not vote.
  final List<List<int>> codePointRanges;

  /// App language code whose font config should render this script when the
  /// default content font cannot (e.g. Tibetan). Null keeps the source
  /// language's font.
  final String? fontLanguage;

  /// The language's single Latin-alphabet rendering. Labelled through l10n
  /// ("Roman transliteration") rather than by [nativeName].
  final bool roman;

  /// Picker label: the script's own name in its own script (देवनागरी,
  /// བོད་ཡིག). The UI substitutes the localised string for [roman] rows.
  String get label => nativeName;

  bool containsCodePoint(int codePoint) {
    for (final range in codePointRanges) {
      if (codePoint >= range[0] && codePoint <= range[1]) return true;
    }
    return false;
  }
}

/// Transliterates texts of one language between scripts, on the phone.
abstract class ScriptConverter {
  /// Language code (as the API reports it) whose texts this converter handles.
  String get languageCode;

  /// Scripts offered to the user, in picker order.
  List<TransliterationScript> get scripts;

  /// Converts plain text (no markup) into [toScriptId]. The source script is
  /// detected from the text. Throws [ArgumentError] on an unknown id.
  String convert(String text, String toScriptId);

  TransliterationScript? scriptById(String? id) {
    if (id == null) return null;
    for (final script in scripts) {
      if (script.id == id) return script;
    }
    return null;
  }

  /// The script most of [sample]'s letters are written in, or null when none
  /// of the known scripts appear.
  ///
  /// A [TransliterationScript.roman] script only wins when the sample holds
  /// no letters of any other script. Stray Latin is common inside texts
  /// written in a native script - loanwords, edition sigla, an English title -
  /// so letting it vote alongside the rest reports Roman for a text that is
  /// plainly Tibetan or Devanagari.
  String? detectScript(String sample) {
    final counts = <String, int>{};
    for (final codePoint in sample.runes) {
      for (final script in scripts) {
        if (script.containsCodePoint(codePoint)) {
          counts[script.id] = (counts[script.id] ?? 0) + 1;
          break;
        }
      }
    }
    return _mostSeen(counts, roman: false) ?? _mostSeen(counts, roman: true);
  }

  /// The most-seen id in [counts] whose script's [TransliterationScript.roman]
  /// is [roman], or null when no such script was seen.
  String? _mostSeen(Map<String, int> counts, {required bool roman}) {
    String? best;
    var bestCount = 0;
    for (final entry in counts.entries) {
      if (scriptById(entry.key)?.roman != roman) continue;
      if (entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
      }
    }
    return best;
  }
}
