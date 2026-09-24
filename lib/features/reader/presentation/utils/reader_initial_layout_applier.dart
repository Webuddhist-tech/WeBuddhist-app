import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_initial_layout.dart';
import 'package:flutter_pecha/features/reader/domain/layout/reader_layout_context.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_context_layout_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_secondary_version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Translation languages to try for a seeded reader, most wanted first: what
/// the person picked last time in this context, then this visit's default,
/// then the app content language. Blank and repeated codes are dropped.
List<String> translationCandidates({
  String? remembered,
  String? seeded,
  required String fallback,
}) {
  final seen = <String>{};
  return [
    for (final code in [remembered, seeded, fallback])
      if (code != null)
        if (normalizeReaderLanguageCode(code).isNotEmpty &&
            seen.add(normalizeReaderLanguageCode(code)))
          normalizeReaderLanguageCode(code),
  ];
}

/// Sets a reader up the first time its text is on screen, once per reader.
///
/// In the library it does what the globe button used to do: fill the
/// translation from Settings language when the app-wide switch is already on.
/// Everywhere else it seeds the context's defaults (`resolveInitialLayout`)
/// into the dual settings and fills the translation the layout, or the
/// person's last pick in that context, asks for.
///
/// [maybeApply] is safe to call repeatedly; it waits until both the text's
/// language and its list of translations are known and then runs once.
class ReaderInitialLayoutApplier {
  final AppLogger _logger = AppLogger('ReaderInitialLayout');
  bool _applied = false;

  Future<void> maybeApply({
    required WidgetRef ref,
    required BuildContext context,
    required ReaderParams params,
  }) async {
    if (_applied) return;
    final textDetail = ref.read(readerNotifierProvider(params)).textDetail;
    if (textDetail == null) return;
    final languagesAsync = ref.read(readerLanguagesProvider(params.textId));
    if (!languagesAsync.hasValue && !languagesAsync.hasError) return;
    _applied = true;

    final scope = params.settingsScope;
    final languages = languagesAsync.valueOrNull ?? const [];
    try {
      if (scope.context == ReaderLayoutContext.library) {
        await _applyLibrary(
          ref: ref,
          context: context,
          params: params,
          textLanguage: textDetail.language,
          textVersionId: textDetail.id,
        );
        return;
      }
      await _applyContext(
        ref: ref,
        context: context,
        params: params,
        textLanguage: textDetail.language,
        textVersionId: textDetail.id,
        translationLanguages: [for (final language in languages) language.code],
      );
    } catch (e, st) {
      // The sheet still lets the person pick by hand.
      _logger.warning('Initial layout for ${scope.textId} not applied', e, st);
    }
  }

  /// Today's globe-button behaviour: the app-wide switch decides, Settings
  /// language fills the slot.
  Future<void> _applyLibrary({
    required WidgetRef ref,
    required BuildContext context,
    required ReaderParams params,
    required String textLanguage,
    required String textVersionId,
  }) async {
    final scope = params.settingsScope;
    final dual = ref.read(readerDualSettingsProvider(scope));
    if (!dual.secondaryEnabled || dual.secondary.versionId != null) return;
    final navLanguage = params.language?.trim();
    await fillSettingsLanguageSecondary(
      ref: ref,
      context: context,
      scope: scope,
      sourceLanguage:
          navLanguage != null && navLanguage.isNotEmpty
              ? navLanguage
              : textLanguage,
      sourceVersionId: textVersionId,
    );
  }

  Future<void> _applyContext({
    required WidgetRef ref,
    required BuildContext context,
    required ReaderParams params,
    required String textLanguage,
    required String textVersionId,
    required List<String> translationLanguages,
  }) async {
    final scope = params.settingsScope;
    final layout = resolveInitialLayout(
      context: scope.context,
      textLanguage: textLanguage,
      uiLanguage: ref.read(contentLanguageProvider),
      translationLanguages: translationLanguages,
      converterScripts:
          ref
              .read(transliterationServiceProvider)
              .converterFor(textLanguage)
              ?.scripts ??
          const [],
      listLanguage: params.language,
    );
    if (layout == null) return;

    final notifier = ref.read(readerDualSettingsProvider(scope).notifier);
    notifier.seed(layout, language: textLanguage);

    // The person's own picks in this context win; they may still be loading.
    await ref.read(readerContextLayoutProvider(scope.context).notifier).loaded;
    if (!context.mounted) return;
    final prefs = ref.read(readerContextLayoutProvider(scope.context));
    final translationOn = prefs.translationOn ?? layout.translationOn;
    if (!translationOn) return;
    if (ref.read(readerDualSettingsProvider(scope)).secondary.versionId != null) {
      return;
    }

    final filled = await fillSecondaryWithLanguages(
      ref: ref,
      context: context,
      scope: scope,
      sourceLanguage: textLanguage,
      sourceVersionId: textVersionId,
      candidates: translationCandidates(
        remembered: prefs.translationLanguage,
        seeded: layout.translationLanguage,
        fallback: ref.read(contentLanguageProvider),
      ),
    );
    // A stored "on" already shows through the mirror; only a seeded default
    // needs switching on, and only now that there is a version to show.
    if (filled != null && prefs.translationOn == null) {
      notifier.seedTranslationOn();
    }
  }
}
