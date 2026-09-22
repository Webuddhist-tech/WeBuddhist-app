import 'package:flutter_pecha/features/reader/domain/transliteration/transliteration_service.dart';
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
    html: transliterateSegmentHtml(
      service,
      html: html,
      language: language,
      scriptId: scriptId,
    ),
    fontLanguage: service.fontLanguageFor(language, scriptId) ?? language,
  );
}

/// [html] as the reader shows it: transliterated into [scriptId] when one is
/// picked for [language], otherwise unchanged. Shared by the verse widgets
/// and the copy action, so what is copied is what is on screen.
String transliterateSegmentHtml(
  TransliterationService service, {
  required String html,
  required String language,
  required String? scriptId,
}) {
  if (scriptId == null) return html;
  return service.convertHtml(
    html,
    languageCode: language,
    toScriptId: scriptId,
  );
}
