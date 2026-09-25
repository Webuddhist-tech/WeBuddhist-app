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
/// Hindi and Nepali read Devanagari, Mongolian reads Cyrillic, Tibetan readers
/// see the text as written, and everyone else gets the Roman row. Chinese has
/// no converter yet, so it reads Roman until a library file exists. A script
/// the converter does not offer falls back to Roman, and a language with no
/// converter gets null.
String? scriptIdForUiLanguage(
  String uiLanguage,
  Iterable<TransliterationScript> scripts,
) {
  final ui = normalizeReaderLayoutLanguage(uiLanguage);
  if (ui == 'bo') return null;
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
/// [listLanguage] is the language picked on the chant list, when the reader
/// was opened from one.
///
/// - Event: the original stays on, in the reader's script; the translation is
///   the UI language, else English (people must be able to follow along),
///   else off. A text already in the UI language is shown as written.
/// - Plan, and chants opened without a list language: only the translation in
///   the UI language when the text offers one; otherwise the text as written.
/// - Chant opened from the list in the language it was loaded in: as written,
///   since the list already handed over that language's edition.
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

  switch (context) {
    case ReaderLayoutContext.library:
      return null;

    case ReaderLayoutContext.event:
      if (text == ui) return const ReaderInitialLayout.asWritten();
      final String? translation;
      if (offered.contains(ui)) {
        translation = ui;
      } else if (offered.contains('en') && text != 'en') {
        translation = 'en';
      } else {
        translation = null;
      }
      return ReaderInitialLayout(
        originalVisible: true,
        originalScriptId: scriptIdForUiLanguage(ui, converterScripts),
        translationOn: translation != null,
        translationLanguage: translation,
      );

    case ReaderLayoutContext.chant:
      final list =
          listLanguage == null ? '' : normalizeReaderLayoutLanguage(listLanguage);
      if (list.isNotEmpty && list == text) {
        return const ReaderInitialLayout.asWritten();
      }
      return _translationOnly(text: text, ui: ui, offered: offered);

    case ReaderLayoutContext.plan:
      return _translationOnly(text: text, ui: ui, offered: offered);
  }
}

/// Translation languages to try, most wanted first: what the person picked
/// last time in this context, then this visit's default, then the app
/// content language. Blank and repeated codes are dropped.
List<String> translationCandidates({
  String? remembered,
  String? seeded,
  required String fallback,
}) {
  final seen = <String>{};
  return [
    for (final code in [remembered, seeded, fallback])
      if (code != null)
        if (normalizeReaderLayoutLanguage(code).isNotEmpty &&
            seen.add(normalizeReaderLayoutLanguage(code)))
          normalizeReaderLayoutLanguage(code),
  ];
}

ReaderInitialLayout _translationOnly({
  required String text,
  required String ui,
  required Set<String> offered,
}) {
  if (ui != text && offered.contains(ui)) {
    return ReaderInitialLayout(
      originalVisible: false,
      translationOn: true,
      translationLanguage: ui,
    );
  }
  return const ReaderInitialLayout.asWritten();
}
