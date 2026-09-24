import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
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

/// Resolves the version for a just-picked secondary language:
/// - different language than Main → first available version,
/// - same language as Main → first version whose id differs from Main's,
/// - nothing usable → mark the slot [ReaderSlotConfig.versionUnavailable].
Future<void> autoSelectSecondaryVersion({
  required WidgetRef ref,
  required String textId,
  required ReaderSlotConfig slot,
  required ReaderSlotConfig mainConfig,
  required int resolveGeneration,
}) async {
  final notifier = ref.read(readerDualSettingsProvider(textId).notifier);
  final query = ReaderLanguageQuery(
    textId: textId,
    language: slot.languageCode,
  );

  bool isCurrentResolve() =>
      notifier.secondaryResolveGeneration == resolveGeneration;

  try {
    final versions = translationVersions(
      await ref.read(readerVersionsProvider(query).future),
    );
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

/// Fills the secondary slot from Settings language and turns it on.
///
/// Does not call [ReaderDualSettingsNotifier.replacePrimary] — the chant /
/// on-screen text stays on top. Returns false when Settings language is the
/// same as the source, missing for this text, or has no usable version.
Future<bool> fillSettingsLanguageSecondary({
  required WidgetRef ref,
  required BuildContext context,
  required String textId,
  required String sourceLanguage,
  String? sourceVersionId,
}) async {
  final settingsLang = normalizeReaderLanguageCode(
    ref.read(contentLanguageProvider),
  );
  if (settingsLang.isEmpty) return false;
  if (readerLanguagesMatch(settingsLang, sourceLanguage)) return false;

  final notifier = ref.read(readerDualSettingsProvider(textId).notifier);
  final enabledGeneration = notifier.secondaryEnabledGeneration;
  final startResolveGeneration = notifier.secondaryResolveGeneration;
  bool toggleUnchanged() =>
      notifier.secondaryEnabledGeneration == enabledGeneration;
  // True while nothing else (e.g. a manual pick in the settings screen) has
  // written the secondary slot since this fill started.
  bool slotUnchanged() =>
      notifier.secondaryResolveGeneration == startResolveGeneration;

  final languages = translationLanguages(
    await ref.read(readerLanguagesProvider(textId).future),
  );
  if (!toggleUnchanged() || !slotUnchanged()) return false;
  ReaderLanguageOption? option;
  for (final language in languages) {
    if (readerLanguagesMatch(language.code, settingsLang)) {
      option = language;
      break;
    }
  }
  if (option == null) return false;
  if (!context.mounted) return false;

  final current = ref.read(readerDualSettingsProvider(textId)).secondary;
  if (current.versionId != null &&
      readerLanguagesMatch(current.languageCode, settingsLang)) {
    notifier.setSecondaryEnabled(true);
    return true;
  }

  final slot = ReaderSlotConfig(
    languageCode: option.code,
    languageLabel: getLanguageName(option.code, context),
  );
  notifier.replaceSecondary(slot);
  final resolveGeneration = notifier.secondaryResolveGeneration;

  await autoSelectSecondaryVersion(
    ref: ref,
    textId: textId,
    slot: slot,
    mainConfig: ReaderSlotConfig(
      languageCode: sourceLanguage,
      languageLabel: getLanguageName(sourceLanguage, context),
      versionId: sourceVersionId,
    ),
    resolveGeneration: resolveGeneration,
  );

  if (!toggleUnchanged()) return false;
  final filled = ref.read(readerDualSettingsProvider(textId)).secondary;
  if (filled.versionId == null) return false;
  notifier.setSecondaryEnabled(true);
  return true;
}
