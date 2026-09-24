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

/// Resolves the version for a just-picked secondary language:
/// - different language than Main → first available version,
/// - same language as Main → first version whose id differs from Main's,
/// - nothing usable → mark the slot [ReaderSlotConfig.versionUnavailable].
Future<void> autoSelectSecondaryVersion({
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
    final versions = await ref.read(readerVersionsProvider(query).future);
    if (!isCurrentResolve()) return;

    final bool sameLanguageAsMain = readerLanguagesMatch(
      slot.languageCode,
      mainConfig.languageCode,
    );

    ReaderVersionDetail? chosen;
    for (final version in versions) {
      if (sameLanguageAsMain && version.id == mainConfig.versionId) continue;
      chosen = version;
      break;
    }

    if (!isCurrentResolve()) return;

    if (chosen == null) {
      notifier.replaceSecondary(slot.copyWith(versionUnavailable: true));
      return;
    }
    notifier.replaceSecondary(
      slot.copyWith(
        versionId: chosen.id,
        versionLabel: chosen.title,
        versionUnavailable: false,
      ),
    );
  } catch (_) {
    if (!isCurrentResolve()) return;
    notifier.replaceSecondary(slot.copyWith(versionUnavailable: true));
  }
}

/// Fills the secondary slot with the first of [candidates] the text offers
/// and resolves its version. Candidates equal to [sourceLanguage] are
/// skipped: the on-screen text stays on top, and this never calls
/// [ReaderDualSettingsNotifier.replacePrimary].
///
/// Returns the language filled, or null when none is offered, the switch was
/// toggled meanwhile, or no usable version exists. Leaves the translation
/// switch alone; callers decide whether a filled slot turns it on.
Future<String?> fillSecondaryWithLanguages({
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
  if (wanted.isEmpty) return null;

  final notifier = ref.read(readerDualSettingsProvider(scope).notifier);
  final enabledGeneration = notifier.secondaryEnabledGeneration;
  final startResolveGeneration = notifier.secondaryResolveGeneration;
  bool toggleUnchanged() =>
      notifier.secondaryEnabledGeneration == enabledGeneration;
  // True while nothing else (e.g. a manual pick in the settings screen) has
  // written the secondary slot since this fill started.
  bool slotUnchanged() =>
      notifier.secondaryResolveGeneration == startResolveGeneration;

  final languages = await ref.read(
    readerLanguagesProvider(scope.textId).future,
  );
  if (!toggleUnchanged() || !slotUnchanged()) return null;
  ReaderLanguageOption? option;
  for (final code in wanted) {
    for (final language in languages) {
      if (readerLanguagesMatch(language.code, code)) {
        option = language;
        break;
      }
    }
    if (option != null) break;
  }
  if (option == null) return null;
  if (!context.mounted) return null;

  final current = ref.read(readerDualSettingsProvider(scope)).secondary;
  if (current.versionId != null &&
      readerLanguagesMatch(current.languageCode, option.code)) {
    return option.code;
  }

  final slot = ReaderSlotConfig(
    languageCode: option.code,
    languageLabel: getLanguageName(option.code, context),
  );
  notifier.replaceSecondary(slot);
  final resolveGeneration = notifier.secondaryResolveGeneration;

  await autoSelectSecondaryVersion(
    ref: ref,
    scope: scope,
    slot: slot,
    mainConfig: ReaderSlotConfig(
      languageCode: sourceLanguage,
      languageLabel: getLanguageName(sourceLanguage, context),
      versionId: sourceVersionId,
    ),
    resolveGeneration: resolveGeneration,
  );

  if (!toggleUnchanged()) return null;
  final filled = ref.read(readerDualSettingsProvider(scope)).secondary;
  if (filled.versionId == null) return null;
  return option.code;
}

/// Fills the secondary slot from Settings language and turns it on.
///
/// Returns false when Settings language is the same as the source, missing
/// for this text, or has no usable version.
Future<bool> fillSettingsLanguageSecondary({
  required WidgetRef ref,
  required BuildContext context,
  required ReaderSettingsScope scope,
  required String sourceLanguage,
  String? sourceVersionId,
}) async {
  final settingsLang = normalizeReaderLanguageCode(
    ref.read(contentLanguageProvider),
  );
  if (settingsLang.isEmpty) return false;
  final filled = await fillSecondaryWithLanguages(
    ref: ref,
    context: context,
    scope: scope,
    sourceLanguage: sourceLanguage,
    sourceVersionId: sourceVersionId,
    candidates: [settingsLang],
  );
  if (filled == null) return false;
  ref.read(readerDualSettingsProvider(scope).notifier).setSecondaryEnabled(true);
  return true;
}
