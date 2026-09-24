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

/// What [ReaderInitialLayoutApplier.maybeApply] does with what it has.
enum ReaderInitialLayoutStep {
  /// The text or its list of translations is still loading, or the layout
  /// has already been applied.
  wait,

  /// The list of translations failed to load: seed the layers and the script
  /// so the sheet reads right, and leave the translation to the sheet's
  /// retry, which brings the list and runs the applier again.
  seedOnly,

  /// Both are known: seed and fill the translation, once.
  apply,
}

/// Picks the step for one call: [ReaderInitialLayoutStep.apply] finishes the
/// job; a failed languages request is [ReaderInitialLayoutStep.seedOnly] and
/// never counts as applied, or a retry could no longer fill the translation.
ReaderInitialLayoutStep readerInitialLayoutStep({
  required bool applied,
  required bool hasText,
  required AsyncValue<Object?> languages,
}) {
  if (applied || !hasText) return ReaderInitialLayoutStep.wait;
  if (languages.hasValue) return ReaderInitialLayoutStep.apply;
  if (languages.hasError) return ReaderInitialLayoutStep.seedOnly;
  return ReaderInitialLayoutStep.wait;
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
/// language and its list of translations are known and then runs once. While
/// that list has failed to load it only seeds the layers and the script, and
/// runs for real once the sheet's retry brings the list.
class ReaderInitialLayoutApplier {
  final AppLogger _logger = AppLogger('ReaderInitialLayout');
  bool _applied = false;

  Future<void> maybeApply({
    required WidgetRef ref,
    required BuildContext context,
    required ReaderParams params,
  }) async {
    final textDetail = ref.read(readerNotifierProvider(params)).textDetail;
    final languagesAsync = ref.read(readerLanguagesProvider(params.textId));
    final step = readerInitialLayoutStep(
      applied: _applied,
      hasText: textDetail != null,
      languages: languagesAsync,
    );
    if (step == ReaderInitialLayoutStep.wait || textDetail == null) return;

    final scope = params.settingsScope;
    if (step == ReaderInitialLayoutStep.seedOnly) {
      if (scope.context != ReaderLayoutContext.library) {
        _seed(
          ref: ref,
          params: params,
          textLanguage: textDetail.language,
          translationLanguages: const [],
        );
      }
      return;
    }
    _applied = true;

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

  /// Seeds this visit's defaults for a text in [textLanguage] into the
  /// context's dual settings. Null in the library, whose settings are left
  /// alone.
  ReaderInitialLayout? _seed({
    required WidgetRef ref,
    required ReaderParams params,
    required String textLanguage,
    required List<String> translationLanguages,
  }) {
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
    if (layout == null) return null;
    ref
        .read(readerDualSettingsProvider(scope).notifier)
        .seed(layout, language: textLanguage);
    return layout;
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
    final layout = _seed(
      ref: ref,
      params: params,
      textLanguage: textLanguage,
      translationLanguages: translationLanguages,
    );
    if (layout == null) return;
    final notifier = ref.read(readerDualSettingsProvider(scope).notifier);

    // The person's own picks in this context win; they may still be loading.
    await ref.read(readerContextLayoutProvider(scope.context).notifier).loaded;
    if (!context.mounted) return;
    final prefs = ref.read(readerContextLayoutProvider(scope.context));
    final translationOn = prefs.translationOn ?? layout.translationOn;
    if (!translationOn) return;
    if (ref.read(readerDualSettingsProvider(scope)).secondary.versionId != null) {
      return;
    }

    final enabledGeneration = notifier.secondaryEnabledGeneration;
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
    if (filled != null) {
      // A stored "on" already shows through the mirror; only a seeded default
      // needs switching on, and only now that there is a version to show.
      if (prefs.translationOn == null) notifier.seedTranslationOn();
      return;
    }
    // A stored "on" with nothing to show on this text would leave the sheet
    // claiming a translation the screen does not have. Hold it off for this
    // visit, unless the person touched the switch meanwhile: that is theirs.
    if (prefs.translationOn == true &&
        notifier.secondaryEnabledGeneration == enabledGeneration) {
      notifier.markTranslationUnavailable();
    }
  }
}
