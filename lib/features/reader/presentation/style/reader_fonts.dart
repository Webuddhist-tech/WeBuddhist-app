import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_script.dart';
import 'package:google_fonts/google_fonts.dart';

/// Where a reader font's files come from.
enum ReaderFontSource {
  /// Shipped in `assets/fonts/`, always at hand.
  bundled,

  /// Fetched by google_fonts the first time it is used, then cached.
  google,
}

/// A font a reader line can be set in.
class ReaderFont {
  const ReaderFont.bundled(this.id, this.name, {required this.label})
    : source = ReaderFontSource.bundled;

  const ReaderFont.google(this.id, this.name, {required this.label})
    : source = ReaderFontSource.google;

  /// Saved with the reader's settings; never changes once shipped.
  final String id;

  /// The pubspec family, or the Google Fonts family name.
  final String name;

  /// What the font is called in the reader's font pills.
  final String label;

  final ReaderFontSource source;

  bool get isDownloaded => source == ReaderFontSource.google;

  /// The family to set on a `TextStyle`. A Google font registers each of
  /// its files as a family of its own, so [weight] and [style] pick which
  /// file is asked for; a bundled font has all its weights in one family.
  String family({
    FontWeight weight = FontWeight.w400,
    FontStyle style = FontStyle.normal,
  }) => switch (source) {
    ReaderFontSource.bundled => name,
    ReaderFontSource.google =>
      GoogleFonts.getFont(
            name,
            fontWeight: weight,
            fontStyle: style,
          ).fontFamily ??
          name,
  };
}

/// Which of a verse's lines a font is picked for.
enum ReaderFontLine { original, translation }

/// The fonts the reader offers for each script.
///
/// The lists are placeholders until the fonts are tried on real texts; the
/// first of each list is its default, today's font for that script.
class ReaderFonts {
  ReaderFonts._();

  static const sourceSerif4 = ReaderFont.google(
    'source-serif-4',
    'Source Serif 4',
    label: 'Source Serif 4',
  );
  static const literata = ReaderFont.google(
    'literata',
    'Literata',
    label: 'Literata',
  );
  static const inter = ReaderFont.google('inter', 'Inter', label: 'Inter');

  // BabelStone and Jomolhari ship as modified builds, and their licence
  // keeps those names for the unmodified fonts, so neither label uses them.
  static const babelStone = ReaderFont.bundled(
    'babelstone',
    AppConfig.tibetanContentFont,
    label: 'WB Tibetan Content',
  );
  static const notoSerifTibetan = ReaderFont.bundled(
    'noto-serif-tibetan',
    AppConfig.tibetanSystemFont,
    label: 'Noto Serif Tibetan',
  );
  static const jomolhari = ReaderFont.bundled(
    'jomolhari',
    'WBTibetanUchen',
    label: 'WB Tibetan Uchen',
  );

  static const notoSerifTc = ReaderFont.google(
    'noto-serif-tc',
    'Noto Serif TC',
    label: 'Noto Serif TC',
  );
  static const lxgwWenKaiTc = ReaderFont.google(
    'lxgw-wenkai-tc',
    'LXGW WenKai TC',
    label: 'LXGW WenKai TC',
  );
  static const notoSansTc = ReaderFont.google(
    'noto-sans-tc',
    'Noto Sans TC',
    label: 'Noto Sans TC',
  );

  static const notoSerifDevanagari = ReaderFont.google(
    'noto-serif-devanagari',
    'Noto Serif Devanagari',
    label: 'Noto Serif Devanagari',
  );

  /// Latin section headings, whatever font their lines are in.
  static const latinHeading = literata;
  static const FontWeight headingWeight = FontWeight.w600;

  /// The fonts for [script], its default first. The original and the
  /// translation share a list; a translation's italic comes from its role.
  static List<ReaderFont> forScript(ReaderScript script) => switch (script) {
    // All three cover Cyrillic as well.
    ReaderScript.latin ||
    ReaderScript.cyrillic => const [sourceSerif4, literata, inter],
    ReaderScript.tibetan => const [babelStone, notoSerifTibetan, jomolhari],
    ReaderScript.chinese => const [notoSerifTc, lxgwWenKaiTc, notoSansTc],
    ReaderScript.devanagari => const [notoSerifDevanagari],
  };

  static ReaderFont defaultFor(ReaderScript script) => forScript(script).first;

  /// The font with [id] among [script]'s, if it is one of them.
  static ReaderFont? byId(ReaderScript script, String? id) {
    for (final font in forScript(script)) {
      if (font.id == id) return font;
    }
    return null;
  }
}

/// The fonts picked for each line and script. Only picks other than the
/// script's default are kept.
class ReaderFontChoices extends Equatable {
  const ReaderFontChoices([this.picks = const {}]);

  /// Font ids by line, then by script name.
  final Map<ReaderFontLine, Map<ReaderScript, String>> picks;

  /// The font for [line] in [script]: its pick, or the default when nothing
  /// was picked or the picked font is no longer offered.
  ReaderFont fontFor(ReaderFontLine line, ReaderScript script) =>
      ReaderFonts.byId(script, picks[line]?[script]) ??
      ReaderFonts.defaultFor(script);

  /// These choices with [font] picked for [line] in [script].
  ReaderFontChoices pick(
    ReaderFontLine line,
    ReaderScript script,
    ReaderFont font,
  ) {
    final next = {
      for (final entry in picks.entries)
        entry.key: Map<ReaderScript, String>.of(entry.value),
    };
    final forLine = next.putIfAbsent(line, () => {});
    if (font.id == ReaderFonts.defaultFor(script).id) {
      forLine.remove(script);
    } else {
      forLine[script] = font.id;
    }
    next.removeWhere((_, scripts) => scripts.isEmpty);
    return ReaderFontChoices(next);
  }

  /// The downloaded fonts picked for a page whose originals are in
  /// [original] and translations in [translation]: what to load before the
  /// page shows. Defaults are left to load as they always have.
  List<ReaderFont> pickedDownloads({
    ReaderScript? original,
    ReaderScript? translation,
  }) =>
      {
        if (original != null)
          _pickedDownload(ReaderFontLine.original, original),
        if (translation != null)
          _pickedDownload(ReaderFontLine.translation, translation),
      }.nonNulls.toList();

  ReaderFont? _pickedDownload(ReaderFontLine line, ReaderScript script) {
    final font = fontFor(line, script);
    final isDefault = font.id == ReaderFonts.defaultFor(script).id;
    return font.isDownloaded && !isDefault ? font : null;
  }

  String toJson() => jsonEncode({
    for (final line in picks.entries)
      line.key.name: {
        for (final script in line.value.entries) script.key.name: script.value,
      },
  });

  /// Reads [toJson]'s output; anything it does not recognise is dropped.
  factory ReaderFontChoices.fromJson(String? json) {
    if (json == null || json.isEmpty) return const ReaderFontChoices();
    Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return const ReaderFontChoices();
    }
    if (decoded is! Map) return const ReaderFontChoices();
    var choices = const ReaderFontChoices();
    for (final line in ReaderFontLine.values) {
      final scripts = decoded[line.name];
      if (scripts is! Map) continue;
      for (final script in ReaderScript.values) {
        final id = scripts[script.name];
        final font = ReaderFonts.byId(script, id is String ? id : null);
        if (font != null) choices = choices.pick(line, script, font);
      }
    }
    return choices;
  }

  @override
  List<Object?> get props => [
    for (final line in ReaderFontLine.values)
      for (final script in ReaderScript.values) picks[line]?[script],
  ];
}
