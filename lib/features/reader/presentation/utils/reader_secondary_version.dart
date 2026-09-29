import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String normalizeReaderLanguageCode(String code) => code.trim().toLowerCase();

bool readerLanguagesMatch(String a, String b) =>
    normalizeReaderLanguageCode(a) == normalizeReaderLanguageCode(b);

/// Languages that have something to pick as a translation.
List<ReaderLanguageOption> translationLanguages(
  List<ReaderLanguageOption> languages,
) => [
  for (final language in languages)
    if (language.translationCount > 0) language,
];

/// Versions that can be a translation: root texts are only the original.
List<ReaderVersionDetail> translationVersions(
  List<ReaderVersionDetail> versions,
) => [
  for (final version in versions)
    if (!version.isRoot) version,
];

/// How [autoSelectSecondaryVersion] left the secondary slot.
enum SecondaryResolveOutcome {
  /// A version is in the slot.
  selected,

  /// The language has no usable version; the slot is marked
  /// [ReaderSlotConfig.versionUnavailable].
  noVersion,

  /// The versions request failed; the slot is marked
  /// [ReaderSlotConfig.versionUnavailable], though a version may exist.
  failed,

  /// Something else wrote the slot meanwhile; it was left alone.
  superseded,
}

/// Resolves the version for a just-picked secondary language:
/// - the edition picked for this text last time in this context, when the
///   language offers it
///   ([ReaderDualSettingsNotifier.rememberedTranslationVersionId]),
/// - else the edition the reader was opened with, when the language offers
///   it ([ReaderDualSettingsNotifier.openedTranslationVersionId]),
/// - else, different language than Main → first available version,
/// - same language as Main → first version whose id differs from Main's,
/// - nothing usable → mark the slot [ReaderSlotConfig.versionUnavailable].
///
/// The resolved slot is written with
/// [ReaderDualSettingsNotifier.fillSecondary]: whether the language was the
/// person's pick is up to the caller.
Future<SecondaryResolveOutcome> autoSelectSecondaryVersion({
  required WidgetRef ref,
  required ReaderSettingsScope scope,
  required ReaderSlotConfig slot,
  required ReaderSlotConfig mainConfig,
  required int resolveGeneration,
}) async {
  final notifier = ref.read(readerDualSettingsProvider(scope).notifier);
  final query = ReaderLanguageQuery(
    textId: scope.textId,
    language: slot.languageCode,
  );

  bool isCurrentResolve() =>
      notifier.secondaryResolveGeneration == resolveGeneration;

  try {
    final versions = translationVersions(
      await ref.read(readerVersionsProvider(query).future),
    );
    if (!isCurrentResolve()) return SecondaryResolveOutcome.superseded;

    final bool sameLanguageAsMain = readerLanguagesMatch(
      slot.languageCode,
      mainConfig.languageCode,
    );

    final remembered = notifier.rememberedTranslationVersionId;
    final opened = notifier.openedTranslationVersionId;
    ReaderVersionDetail? chosen;
    ReaderVersionDetail? openedVersion;
    ReaderVersionDetail? first;
    for (final version in versions) {
      if (sameLanguageAsMain && version.id == mainConfig.versionId) continue;
      if (version.id == remembered) {
        chosen = version;
        break;
      }
      if (version.id == opened) openedVersion ??= version;
      first ??= version;
    }
    chosen ??= openedVersion ?? first;

    if (chosen == null) {
      notifier.fillSecondary(slot.copyWith(versionUnavailable: true));
      return SecondaryResolveOutcome.noVersion;
    }
    notifier.fillSecondary(
      slot.copyWith(
        versionId: chosen.id,
        versionLabel: chosen.title,
        versionUnavailable: false,
      ),
    );
    return SecondaryResolveOutcome.selected;
  } catch (_) {
    if (!isCurrentResolve()) return SecondaryResolveOutcome.superseded;
    notifier.fillSecondary(slot.copyWith(versionUnavailable: true));
    return SecondaryResolveOutcome.failed;
  }
}

/// How [fillSecondaryWithLanguages] left the secondary slot.
enum SecondaryFillOutcome {
  /// A version of one of the candidates is in the slot.
  filled,

  /// No candidate is offered or has a usable version: the slot holds the
  /// last one's "not available" mark, or is untouched when none was tried.
  unavailable,

  /// Nothing was filled and at least one candidate's versions request
  /// failed, so a translation may exist and trying again can find it. The
  /// slot holds the last candidate's "not available" mark.
  failed,

  /// The switch was toggled, the slot picked by hand or the screen closed
  /// meanwhile; the slot is left to whoever did that.
  superseded,
}

/// Fills the secondary slot with the first of [candidates] the text offers a
/// usable version for, trying them in order, and resolves that version.
/// Candidates equal to [sourceLanguage] are skipped: the on-screen text stays
/// on top, and this never calls [ReaderDualSettingsNotifier.replacePrimary].
/// A candidate the text lists but has no version for, or whose versions
/// request fails, is passed over; only when it is the last one does the slot
/// stay marked unavailable.
///
/// Leaves the translation switch alone; callers decide from the outcome
/// whether a filled slot turns it on, and must not read a
/// [SecondaryFillOutcome.superseded] slot as empty.
Future<SecondaryFillOutcome> fillSecondaryWithLanguages({
  required WidgetRef ref,
  required BuildContext context,
  required ReaderSettingsScope scope,
  required String sourceLanguage,
  required List<String> candidates,
  String? sourceVersionId,
}) async {
  final wanted = [
    for (final candidate in candidates)
      if (normalizeReaderLanguageCode(candidate).isNotEmpty &&
          !readerLanguagesMatch(candidate, sourceLanguage))
        normalizeReaderLanguageCode(candidate),
  ];
  if (wanted.isEmpty) return SecondaryFillOutcome.unavailable;

  final notifier = ref.read(readerDualSettingsProvider(scope).notifier);
  final enabledGeneration = notifier.secondaryEnabledGeneration;
  final startResolveGeneration = notifier.secondaryResolveGeneration;
  bool toggleUnchanged() =>
      notifier.secondaryEnabledGeneration == enabledGeneration;
  // True while nothing else (e.g. a manual pick in the settings screen) has
  // written the secondary slot since this fill started.
  bool slotUnchanged() =>
      notifier.secondaryResolveGeneration == startResolveGeneration;

  final languages = translationLanguages(
    await ref.read(readerLanguagesProvider(scope.textId).future),
  );
  if (!toggleUnchanged() || !slotUnchanged()) {
    return SecondaryFillOutcome.superseded;
  }

  ReaderLanguageOption? offered(String code) {
    for (final language in languages) {
      if (readerLanguagesMatch(language.code, code)) return language;
    }
    return null;
  }

  final options = <ReaderLanguageOption>[];
  for (final code in wanted) {
    final option = offered(code);
    if (option != null) options.add(option);
  }
  if (!context.mounted) return SecondaryFillOutcome.superseded;
  if (options.isEmpty) return SecondaryFillOutcome.unavailable;

  final mainConfig = ReaderSlotConfig(
    languageCode: sourceLanguage,
    languageLabel: getLanguageName(sourceLanguage, context),
    versionId: sourceVersionId,
  );

  // A slot already in a candidate's language is done, unless this text has
  // another edition remembered in that same language: that one replaces it.
  final remembered = notifier.rememberedTranslationVersionId;
  var anyFailed = false;
  for (final option in options) {
    if (!context.mounted) return SecondaryFillOutcome.superseded;
    final current = ref.read(readerDualSettingsProvider(scope)).secondary;
    if (current.versionId != null &&
        readerLanguagesMatch(current.languageCode, option.code)) {
      if (remembered == null || current.versionId == remembered) {
        return SecondaryFillOutcome.filled;
      }
      final generation = notifier.secondaryResolveGeneration;
      final offersRemembered = await _languageOffersVersion(
        ref: ref,
        textId: scope.textId,
        language: option.code,
        versionId: remembered,
      );
      if (!toggleUnchanged() ||
          !context.mounted ||
          notifier.secondaryResolveGeneration != generation) {
        return SecondaryFillOutcome.superseded;
      }
      // Re-resolving would only clear the slot and put the same edition
      // back, reloading the translation for nothing.
      if (!offersRemembered) return SecondaryFillOutcome.filled;
    }

    final slot = ReaderSlotConfig(
      languageCode: option.code,
      languageLabel: getLanguageName(option.code, context),
    );
    // The app's choice, not the person's pick.
    notifier.fillSecondary(slot);
    final resolved = await autoSelectSecondaryVersion(
      ref: ref,
      scope: scope,
      slot: slot,
      mainConfig: mainConfig,
      resolveGeneration: notifier.secondaryResolveGeneration,
    );

    if (!toggleUnchanged() || !context.mounted) {
      return SecondaryFillOutcome.superseded;
    }
    final filled = ref.read(readerDualSettingsProvider(scope)).secondary;
    if (filled.versionId != null &&
        readerLanguagesMatch(filled.languageCode, option.code)) {
      return SecondaryFillOutcome.filled;
    }
    // Try the next candidate only while the slot still holds this fill's
    // "not available" mark; anything else in it is a pick made meanwhile.
    if (filled != slot.copyWith(versionUnavailable: true)) {
      return SecondaryFillOutcome.superseded;
    }
    if (resolved == SecondaryResolveOutcome.failed) anyFailed = true;
  }
  return anyFailed
      ? SecondaryFillOutcome.failed
      : SecondaryFillOutcome.unavailable;
}

/// Whether [language]'s translation editions of [textId] include
/// [versionId]; false when they cannot be fetched.
Future<bool> _languageOffersVersion({
  required WidgetRef ref,
  required String textId,
  required String language,
  required String versionId,
}) async {
  try {
    final versions = translationVersions(
      await ref.read(
        readerVersionsProvider(
          ReaderLanguageQuery(textId: textId, language: language),
        ).future,
      ),
    );
    return versions.any((version) => version.id == versionId);
  } catch (_) {
    return false;
  }
}

/// Fills the secondary slot with the translation this reader prefers
/// ([ReaderDualSettingsNotifier.preferredTranslationLanguages]: Settings
/// language in the library; the last pick, this visit's default, then
/// Settings language elsewhere) and turns it on.
///
/// Returns false when none of those is offered for this text apart from the
/// source language, or none has a usable version.
Future<bool> fillPreferredSecondary({
  required WidgetRef ref,
  required BuildContext context,
  required ReaderSettingsScope scope,
  required String sourceLanguage,
  String? sourceVersionId,
}) async {
  final notifier = ref.read(readerDualSettingsProvider(scope).notifier);
  final outcome = await fillSecondaryWithLanguages(
    ref: ref,
    context: context,
    scope: scope,
    sourceLanguage: sourceLanguage,
    sourceVersionId: sourceVersionId,
    candidates: notifier.preferredTranslationLanguages(
      contentLanguage: ref.read(contentLanguageProvider),
    ),
  );
  if (outcome != SecondaryFillOutcome.filled) return false;
  notifier.setSecondaryEnabled(true);
  return true;
}
