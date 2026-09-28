import 'package:flutter_pecha/features/reader/data/models/flattened_content.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/transliteration_service.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
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
/// for [language] in the reader [scope], when they picked one. Watches only
/// that language's pick.
PrimarySegmentHtml primarySegmentHtml(
  WidgetRef ref, {
  required String? content,
  required String language,
  required ReaderSettingsScope scope,
}) {
  final html = normalizeSegmentHtml(content);
  final scriptId = ref.watch(
    readerOriginalScriptProvider(
      ReaderScriptScope(scope: scope, language: language),
    ),
  );
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

/// How much text [scriptDetectionSample] gathers. A few verses settle the
/// script beyond doubt and the reader can hold thousands of them.
const int _sampleLimit = 400;

/// Plain text from the first loaded verses, for [ScriptConverter.detectScript].
///
/// The body is the only honest witness to the script a text is written in.
/// Its title is not: catalogues romanise Tibetan and Pali titles as a matter
/// of course, so detecting from one reports Roman for a text whose verses are
/// in Uchen - and the Roman row, the one worth having, then looks like the
/// script already on screen.
String scriptDetectionSample(FlattenedContent? content) {
  if (content == null) return '';
  final buffer = StringBuffer();
  for (final item in content.items) {
    final segment = item.segment?.content;
    if (segment == null || segment.isEmpty) continue;
    // Markup is stripped so tag names and entities cannot vote for Roman.
    buffer.write(segment.replaceAll(TransliterationService.markup, ' '));
    if (buffer.length >= _sampleLimit) break;
  }
  return buffer.toString();
}
