import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/pali_script_converter.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/script_converter.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/tibetan_script_converter.dart';

/// Looks up the [ScriptConverter] for a text's language and transliterates
/// segment HTML with it, leaving markup untouched.
///
/// Results are memoised per (language, script, html) because the reader
/// rebuilds segment widgets on every scroll and some Pali texts run to
/// thousands of segments.
class TransliterationService {
  TransliterationService(List<ScriptConverter> converters)
    : _converters = {
        for (final converter in converters)
          normalizeLanguage(converter.languageCode): converter,
      };

  factory TransliterationService.standard() => TransliterationService([
    PaliScriptConverter(),
    // Change the mark style here once the team has picked one.
    TibetanScriptConverter(markStyle: TibetanMarkStyle.lineBreak),
  ]);

  static const int maxCachedEntries = 4000;

  /// Tags and character entities: converted around, never through, so a
  /// `<br>` or `&amp;` is not read as Roman Pali.
  static final RegExp markup = RegExp(r'<[^>]*>|&[#\w]+;');

  /// The name of the element a [markup] match opens or closes, lower-cased,
  /// or null when the match is an entity, a comment or a doctype.
  static final RegExp _tagName = RegExp(r'^<\s*(/?)\s*([A-Za-z][\w:-]*)');

  /// A footnote body or its marker. Their text is the editor's English -
  /// "So PTS; see Burmese ed. page 12." - not the verse, so transliterating
  /// it would turn a note into gibberish. `SegmentHtmlWidget` styles both
  /// classes, so they are a real part of this corpus.
  static final RegExp _footnoteClass = RegExp(
    r"""\bclass\s*=\s*["'][^"']*\bfootnote""",
  );

  final Map<String, ScriptConverter> _converters;
  final LinkedHashMap<String, String> _cache = LinkedHashMap();
  final AppLogger _logger = AppLogger('Transliteration');

  static String normalizeLanguage(String code) => code.trim().toLowerCase();

  ScriptConverter? converterFor(String languageCode) =>
      _converters[normalizeLanguage(languageCode)];

  bool supports(String languageCode) => converterFor(languageCode) != null;

  /// The script [scriptId] names for [languageCode], or null when either is
  /// unknown.
  TransliterationScript? script(String languageCode, String? scriptId) =>
      converterFor(languageCode)?.scriptById(scriptId);

  /// Language code to pick the font for text rendered in [scriptId]; null
  /// when the source language's font should stay.
  String? fontLanguageFor(String languageCode, String scriptId) =>
      script(languageCode, scriptId)?.fontLanguage;

  /// [html] with its text transliterated into [toScriptId]. Returns the input
  /// unchanged when the language has no converter or the conversion fails.
  String convertHtml(
    String html, {
    required String languageCode,
    required String toScriptId,
  }) {
    final converter = converterFor(languageCode);
    if (converter == null || html.isEmpty) return html;

    final key = '${converter.languageCode}\u0000$toScriptId\u0000$html';
    final cached = _cache[key];
    if (cached != null) return cached;

    String result;
    try {
      // Name of the footnote element being skipped, and how deep we are
      // inside it (the same tag can nest: an <i> within an <i class=footnote>).
      String? skippedTag;
      var skipDepth = 0;
      result = html.splitMapJoin(
        markup,
        onMatch: (match) {
          final raw = match[0]!;
          final tag = _tagName.firstMatch(raw);
          if (tag == null) return raw;
          final name = tag[2]!.toLowerCase();
          final closing = tag[1] == '/';
          if (skipDepth > 0) {
            if (name == skippedTag) {
              skipDepth += closing ? -1 : 1;
              if (skipDepth == 0) skippedTag = null;
            }
          } else if (!closing &&
              !raw.endsWith('/>') &&
              _footnoteClass.hasMatch(raw)) {
            skippedTag = name;
            skipDepth = 1;
          }
          return raw;
        },
        onNonMatch: (text) {
          if (text.isEmpty || skipDepth > 0) return text;
          return _convertText(converter, text, toScriptId);
        },
      );
    } catch (e, st) {
      _logger.error('Transliteration to $toScriptId failed', e, st);
      result = html;
    }
    _remember(key, result);
    return result;
  }

  /// [text] in [toScriptId], with the line breaks *the converter introduced*
  /// (TibetanMarkStyle.lineBreak) turned into `<br>`, which is what a break
  /// needs to be in HTML.
  ///
  /// Newlines already in [text] are HTML whitespace, not breaks, so each of
  /// its lines is converted on its own and rejoined as it came. Asking
  /// instead whether the input held a newline would drop every break the
  /// converter made in that chunk as soon as the API pretty-printed its HTML.
  static String _convertText(
    ScriptConverter converter,
    String text,
    String toScriptId,
  ) => [
    for (final line in text.split('\n'))
      if (line.isEmpty)
        line
      else
        converter.convert(line, toScriptId).replaceAll('\n', '<br>'),
  ].join('\n');

  void _remember(String key, String value) {
    if (_cache.length >= maxCachedEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  @visibleForTesting
  int get cachedEntries => _cache.length;
}
