import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/script_converter.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A segment's primary line, ready for [SegmentHtmlWidget].
class PrimarySegmentHtml {
  const PrimarySegmentHtml({required this.html, required this.fontLanguage});

  final String html;

  /// Language code to pick the font with — the target script's when the text
  /// was transliterated into one the source font cannot render.
  final String fontLanguage;
}

/// Normalises [content] and transliterates it into the script the user picked
/// for [language], when they picked one. Watches only that language's pick.
PrimarySegmentHtml primarySegmentHtml(
  WidgetRef ref, {
  required String? content,
  required String language,
}) {
  final html = normalizeSegmentHtml(content);
  final scriptId = ref.watch(readerScriptForLanguageProvider(language));
  if (scriptId == null) {
    return PrimarySegmentHtml(html: html, fontLanguage: language);
  }
  final service = ref.watch(transliterationServiceProvider);
  return PrimarySegmentHtml(
    html: service.convertHtml(
      html,
      languageCode: language,
      toScriptId: scriptId,
    ),
    fontLanguage: service.fontLanguageFor(language, scriptId) ?? language,
  );
}

/// What a script row is called: its own name in its own script, or the
/// localised "Roman transliteration" for the Latin-alphabet row.
String transliterationScriptLabel(
  BuildContext context,
  TransliterationScript script,
) => script.roman ? context.l10n.reader_roman_transliteration : script.label;
