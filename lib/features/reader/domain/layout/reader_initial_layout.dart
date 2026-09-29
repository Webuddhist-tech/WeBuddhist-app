import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/script_converter.dart';

/// How the reader is set up the first time a text opens in a
/// [ReaderLayoutContext]: which layers are on, the script the original is
/// shown in and the translation language.
///
/// Null [originalScriptId] means "as written"; null [translationLanguage]
/// means no translation. One layer is always on, and a translation that is on
/// always names a language.
class ReaderInitialLayout extends Equatable {
  const ReaderInitialLayout({
    required this.originalVisible,
    required this.translationOn,
    this.translationLanguage,
    this.originalScriptId,
  }) : assert(
         !translationOn || translationLanguage != null,
         'A translation that is on needs a language',
       ),
       assert(
         originalVisible || translationOn,
         'One layer is always on',
       );

  /// The text as written and nothing else.
  const ReaderInitialLayout.asWritten()
    : this(originalVisible: true, translationOn: false);

  final bool originalVisible;
  final bool translationOn;
  final String? translationLanguage;
  final String? originalScriptId;

  @override
  List<Object?> get props => [
    originalVisible,
    translationOn,
    translationLanguage,
    originalScriptId,
  ];
}

/// Language codes as the resolver compares them: the API and the settings
/// disagree on case and whitespace (`EN`, `en `).
String normalizeReaderLayoutLanguage(String code) => code.trim().toLowerCase();

const String _devanagari = 'Devanagari';
const String _cyrillic = 'Cyrillic';

/// The script a reader of [uiLanguage] chants a transliterated text in, as
/// one of [scripts] (the converter's scripts for the text's language), or null
/// for the text as written.
///
/// Hindi and Nepali read Devanagari, Mongolian reads Cyrillic, and everyone
/// else gets the Roman row. Tibetan readers see the text as written, and so do
/// Chinese readers: there is no transliteration into Chinese. A script the
/// converter does not offer falls back to Roman, and a language with no
/// converter gets null.
String? scriptIdForUiLanguage(
  String uiLanguage,
  Iterable<TransliterationScript> scripts,
) {
  final ui = normalizeReaderLayoutLanguage(uiLanguage);
  if (ui == 'bo' || ui == 'zh') return null;
  final String? wanted = switch (ui) {
    'hi' || 'ne' => _devanagari,
    'mn' => _cyrillic,
    _ => null,
  };
  if (wanted != null) {
    for (final script in scripts) {
      if (script.name == wanted) return script.id;
    }
  }
  for (final script in scripts) {
    if (script.roman) return script.id;
  }
  return null;
}

/// The initial layout for a text of [textLanguage] opened in [context] by a
/// reader whose app language is [uiLanguage]. Null for the library, whose
/// settings are left alone.
///
/// [translationLanguages] are the languages the text offers a translation in.
/// [converterScripts] are the scripts the text's language can be
/// transliterated into on the phone (empty when there is no converter).
/// [listLanguage] is the language the chant was picked in (the chant list or
/// a recitation collection item); only chants use it.
///
/// A chant picked in a language shows that language, whatever the app
/// language: the edition itself as written when it is the text, else only
/// its translation (a translated edition opened under its original).
///
/// Otherwise a text already in the UI language is shown as written, alone,
/// and:
///
/// - Event: the original stays on, in the reader's script, with the
///   translation in the UI language, else English (people must be able to
///   follow along), else none.
/// - Plan and chant: only the translation, in the UI language, else English;
///   the text as written when neither is offered.
ReaderInitialLayout? resolveInitialLayout({
  required ReaderLayoutContext context,
  required String textLanguage,
  required String uiLanguage,
  required Iterable<String> translationLanguages,
  Iterable<TransliterationScript> converterScripts = const [],
  String? listLanguage,
}) {
  final text = normalizeReaderLayoutLanguage(textLanguage);
  final ui = normalizeReaderLayoutLanguage(uiLanguage);
  final offered = {
    for (final language in translationLanguages)
      normalizeReaderLayoutLanguage(language),
  };

  if (context == ReaderLayoutContext.chant) {
    final list = normalizeReaderLayoutLanguage(listLanguage ?? '');
    if (list.isNotEmpty) {
      if (list == text) return const ReaderInitialLayout.asWritten();
      if (offered.contains(list)) {
        return ReaderInitialLayout(
          originalVisible: false,
          translationOn: true,
          translationLanguage: list,
        );
      }
    }
  }

  switch (context) {
    case ReaderLayoutContext.library:
      return null;

    case ReaderLayoutContext.event:
      if (text == ui) return const ReaderInitialLayout.asWritten();
      final translation = _translationFor(text: text, ui: ui, offered: offered);
      return ReaderInitialLayout(
        originalVisible: true,
        originalScriptId: scriptIdForUiLanguage(ui, converterScripts),
        translationOn: translation != null,
        translationLanguage: translation,
      );

    case ReaderLayoutContext.plan:
    case ReaderLayoutContext.chant:
      if (text == ui) return const ReaderInitialLayout.asWritten();
      final translation = _translationFor(text: text, ui: ui, offered: offered);
      if (translation == null) return const ReaderInitialLayout.asWritten();
      return ReaderInitialLayout(
        originalVisible: false,
        translationOn: true,
        translationLanguage: translation,
      );
  }
}

/// Translation languages to try, most wanted first: what the person picked
/// last time in this context, then the language of the edition the reader
/// was opened with, then this visit's default, then the app content
/// language. Blank and repeated codes are dropped.
List<String> translationCandidates({
  String? remembered,
  String? opened,
  String? seeded,
  required String fallback,
}) {
  final seen = <String>{};
  return [
    for (final code in [remembered, opened, seeded, fallback])
      if (code != null)
        if (normalizeReaderLayoutLanguage(code).isNotEmpty &&
            seen.add(normalizeReaderLayoutLanguage(code)))
          normalizeReaderLayoutLanguage(code),
  ];
}

/// The translation a reader of [ui] gets: their own language when the text
/// offers it, else English (never for an English text), else none.
String? _translationFor({
  required String text,
  required String ui,
  required Set<String> offered,
}) {
  if (offered.contains(ui)) return ui;
  if (offered.contains('en') && text != 'en') return 'en';
  return null;
}
