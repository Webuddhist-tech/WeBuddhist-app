import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/script_converter.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart'
    show transliterationServiceProvider;
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/style/reader_style.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_secondary_version.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_bottom_sheet.dart'
    show readerShownLines;
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/picker_state_views.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/reader_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A text the Languages sheet drives besides the one it shows: its settings
/// scope and, until a main text is picked for it, the edition on screen.
class ReaderLanguagesText {
  final ReaderSettingsScope scope;
  final ReaderSlotConfig primaryDisplay;

  const ReaderLanguagesText({
    required this.scope,
    required this.primaryDisplay,
  });
}

/// The Languages sheet (WF21/WF22/WF32): the original with its switch and,
/// when its language can be transliterated on the phone, a chip for each
/// script it can be shown in; then the translation with its switch and a
/// chip for each language. One translation per language: a language picks
/// its translation as the app does, with no list of editions. At least one
/// line stays on: the only one on has a locked, dimmed switch.
///
/// A page reading several texts (a plan task's sources) opens one sheet for
/// all of them: it shows one text's state, lists every language any of them
/// is translated into, and applies each pick to all by language. Each text
/// then shows its own edition in that language, or no translation when it
/// has none; editions are not named or picked, since one belongs to one
/// text only.
class ReaderLanguagesSheet extends ConsumerStatefulWidget {
  const ReaderLanguagesSheet({
    super.key,
    required this.scope,
    required this.primaryDisplay,
    this.sourceSample,
    this.others = const [],
  });

  /// The text and context whose settings this sheet shows and edits.
  final ReaderSettingsScope scope;
  final ReaderSlotConfig primaryDisplay;

  /// Plain text lifted from the loaded segments, used to tell which script
  /// the original is written in. Null (or empty) leaves the script unknown,
  /// which only costs the first row its name. Never the title: titles are
  /// routinely romanised even when the body is not.
  final String? sourceSample;

  /// The page's other texts, which follow every pick made here by language.
  final List<ReaderLanguagesText> others;

  @override
  ConsumerState<ReaderLanguagesSheet> createState() =>
      _ReaderLanguagesSheetState();
}

class _ReaderLanguagesSheetState extends ConsumerState<ReaderLanguagesSheet> {
  bool _filling = false;

  ReaderSettingsScope get _scope => widget.scope;

  ReaderDualSettingsNotifier get _notifier =>
      ref.read(readerDualSettingsProvider(_scope).notifier);

  ReaderSlotConfig get _secondary =>
      ref.read(readerDualSettingsProvider(_scope)).secondary;

  /// The other texts following this sheet, never the shown one twice.
  List<ReaderLanguagesText> get _others => [
    for (final text in widget.others)
      if (text.scope != _scope) text,
  ];

  bool get _isMultiText => _others.isNotEmpty;

  ReaderDualSettingsNotifier _notifierOf(ReaderSettingsScope scope) =>
      ref.read(readerDualSettingsProvider(scope).notifier);

  ReaderSlotConfig _primary() {
    if (_notifier.isPrimaryEdited) {
      return ref.read(readerDualSettingsProvider(_scope)).primary;
    }
    return widget.primaryDisplay;
  }

  /// [_primary] for one of the other texts.
  ReaderSlotConfig _primaryOf(ReaderLanguagesText text) {
    if (_notifierOf(text.scope).isPrimaryEdited) {
      return ref.read(readerDualSettingsProvider(text.scope)).primary;
    }
    return text.primaryDisplay;
  }

  Future<void> _onToggle(bool value) async {
    _notifier.setSecondaryEnabled(value);
    for (final text in _others) {
      _notifierOf(text.scope).setSecondaryEnabled(value);
    }
    if (!value) return;
    final othersFilled = _fillOthersWithoutTranslation();
    if (_secondary.versionId != null) {
      unawaited(othersFilled);
      return;
    }

    setState(() => _filling = true);
    final primary = _primary();
    try {
      await fillPreferredSecondary(
        ref: ref,
        context: context,
        scope: _scope,
        sourceLanguage: primary.languageCode,
        sourceVersionId: primary.versionId,
      );
      await othersFilled;
    } finally {
      if (mounted) setState(() => _filling = false);
    }
  }

  /// Fills the translation of every other text that has none the way the
  /// switch does for the shown text. A failed request leaves that text
  /// without one.
  Future<void> _fillOthersWithoutTranslation() async {
    await Future.wait([
      for (final text in _others)
        if (ref.read(readerDualSettingsProvider(text.scope)).secondary.versionId ==
            null)
          _fillPreferredFor(text),
    ]);
  }

  Future<void> _fillPreferredFor(ReaderLanguagesText text) async {
    final primary = _primaryOf(text);
    try {
      await fillPreferredSecondary(
        ref: ref,
        context: context,
        scope: text.scope,
        sourceLanguage: primary.languageCode,
        sourceVersionId: primary.versionId,
      );
    } catch (_) {
      // Left without a translation; its own switch asks again.
    }
  }

  /// One translation per language: a language picks its translation the
  /// way the app picks one, for every text of the page.
  Future<void> _onLanguageTap(ReaderLanguageOption option) async {
    _notifier.rememberTranslationLanguage(option.code);
    unawaited(
      Future.wait([for (final text in _others) _applyLanguageTo(text, option)]),
    );

    final current = _secondary;
    final sameLanguage = readerLanguagesMatch(
      current.languageCode,
      option.code,
    );
    if (sameLanguage && (current.versionId != null || current.versionUnavailable)) {
      return;
    }

    final slot = ReaderSlotConfig(
      languageCode: option.code,
      languageLabel: getLanguageName(option.code, context),
    );
    _notifier.replaceSecondary(slot);
    final resolveGeneration = _notifier.secondaryResolveGeneration;
    final resolving = ref.read(
      readerSecondaryResolvingProvider(_scope).notifier,
    );
    resolving.state = true;
    try {
      await autoSelectSecondaryVersion(
        ref: ref,
        scope: _scope,
        slot: slot,
        mainConfig: _primary(),
        resolveGeneration: resolveGeneration,
      );
    } finally {
      if (mounted) resolving.state = false;
    }
  }

  /// Picks [option] for one of the other texts: its own edition in that
  /// language, or no translation when it has none.
  Future<void> _applyLanguageTo(
    ReaderLanguagesText text,
    ReaderLanguageOption option,
  ) async {
    final notifier = _notifierOf(text.scope);
    final current = ref.read(readerDualSettingsProvider(text.scope)).secondary;
    if (readerLanguagesMatch(current.languageCode, option.code) &&
        (current.versionId != null || current.versionUnavailable)) {
      return;
    }
    final slot = ReaderSlotConfig(
      languageCode: option.code,
      languageLabel: getLanguageName(option.code, context),
    );
    notifier.replaceSecondary(slot);
    await autoSelectSecondaryVersion(
      ref: ref,
      scope: text.scope,
      slot: slot,
      mainConfig: _primaryOf(text),
      resolveGeneration: notifier.secondaryResolveGeneration,
    );
  }

  void _onScriptTap(String languageCode, String? scriptId) {
    _notifier.setOriginalScript(languageCode, scriptId);
  }

  /// Hiding the original needs a translation on screen, so it switches the
  /// translation on and picks a version the way the Translation switch does.
  Future<void> _onOriginalToggle(bool visible) async {
    _notifier.setOriginalVisible(visible);
    for (final text in _others) {
      _notifierOf(text.scope).setOriginalVisible(visible);
    }
    if (visible) return;
    if (_secondary.versionId != null) {
      unawaited(_fillOthersWithoutTranslation());
      return;
    }
    await _onToggle(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = ReaderPalette.resolve(Theme.of(context), ref);
    final settings = ref.watch(readerDualSettingsProvider(_scope));
    final resolving = ref.watch(readerSecondaryResolvingProvider(_scope));
    final primary = _primary();
    final converter = ref
        .watch(transliterationServiceProvider)
        .converterFor(primary.languageCode);
    final selectedScript =
        converter == null
            ? null
            : ref.watch(
              readerOriginalScriptProvider(
                ReaderScriptScope(
                  scope: _scope,
                  language: primary.languageCode,
                ),
              ),
            );
    final sourceScript = converter?.detectScript(widget.sourceSample ?? '');
    final enabled = settings.secondaryEnabled;
    final busy = resolving || _filling;
    final shown = readerShownLines(settings);
    final originalLanguage = getLanguageName(primary.languageCode, context);
    final secondary = settings.secondary;

    return ReaderSheet(
      title: l10n.reader_languages_title,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReaderSheetGroupTitle(
            '${l10n.reader_original_label} · $originalLanguage',
            trailing: ReaderSheetSwitch(
              value: shown.original,
              // At least one line stays on.
              locked: shown.original && !shown.translation,
              onChanged: busy ? null : _onOriginalToggle,
            ),
          ),
          if (converter != null && shown.original) ...[
            ReaderSheetCapsLabel(l10n.reader_show_script_in(originalLanguage)),
            _ScriptChips(
              converter: converter,
              sourceScriptId: sourceScript,
              selectedScriptId: selectedScript,
              onTap: (id) => _onScriptTap(primary.languageCode, id),
            ),
          ],
          const SizedBox(height: 4),
          const ReaderSheetDivider(),
          const SizedBox(height: 6),
          ReaderSheetGroupTitle(
            l10n.reader_translation_label,
            trailing: ReaderSheetSwitch(
              value: enabled,
              locked: shown.translation && !shown.original,
              onChanged: busy ? null : _onToggle,
            ),
          ),
          if (enabled) ...[
            ReaderSheetCapsLabel(l10n.language),
            _LanguageChips(
              textIds: [
                _scope.textId,
                for (final text in _others) text.scope.textId,
              ],
              secondary: secondary,
              onTap: busy ? null : _onLanguageTap,
            ),
            // One text with no translation in the picked language says so;
            // on a page of several, each text simply shows none.
            if (!_isMultiText && secondary.versionUnavailable)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_languageName(context, secondary.languageCode)} · '
                  '${l10n.version_not_available}',
                  style: readerSheetText(
                    context,
                    ReaderSheetTextRole.label,
                    color: palette.sheetMuted,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Languages are named in their own script (English, བོད་ཡིག, 中文); one
/// without a known native name keeps its name in the app's language.
String _languageName(BuildContext context, String code) =>
    getNativeLanguageName(code) ?? getLanguageName(code, context);

/// The languages any of the page's texts is translated into, as chips; the
/// one on screen is selected.
class _LanguageChips extends ConsumerWidget {
  const _LanguageChips({
    required this.textIds,
    required this.secondary,
    required this.onTap,
  });

  /// The shown text first; the languages of all of them are offered.
  final List<String> textIds;
  final ReaderSlotConfig secondary;
  final ValueChanged<ReaderLanguageOption>? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final asyncLangs = ref.watch(readerLanguagesProvider(textIds.first));
    // The other texts' languages join the list as they arrive.
    final otherLangs = [
      for (final id in textIds.skip(1))
        ref.watch(readerLanguagesProvider(id)).valueOrNull ?? const [],
    ];

    return asyncLangs.when(
      loading: () => const PickerLoading(),
      error:
          (_, __) => PickerError(
            message: l10n.reader_languages_load_error,
            onRetry: () {
              for (final id in textIds) {
                ref.invalidate(readerLanguagesProvider(id));
              }
            },
          ),
      data: (all) {
        final langs = mergedTranslationLanguages([all, ...otherLangs]);
        if (langs.isEmpty) {
          return PickerEmpty(message: l10n.reader_no_languages);
        }
        return ReaderSheetChips(
          spacing: 8,
          children: [
            for (final lang in langs)
              ReaderSheetChip(
                label: _languageName(context, lang.code),
                selected:
                    !secondary.isUnset &&
                    readerLanguagesMatch(lang.code, secondary.languageCode),
                onTap: onTap == null ? null : () => onTap!(lang),
              ),
          ],
        );
      },
    );
  }
}

/// Which chip of [_ScriptChips] is selected, given the user's pick and the
/// script the text is written in.
///
/// The source script has no chip of its own - it *is* the "as written" chip
/// - so a pick naming it is the same choice, and passing it through would
/// leave nothing selected (a Sinhala pick opened on a Sinhala text).
@visibleForTesting
String? activeScriptRow({
  required String? selectedScriptId,
  required String? sourceScriptId,
}) => selectedScriptId == sourceScriptId ? null : selectedScriptId;

/// Scripts the original can be shown in, as chips: first the text as
/// written (its own script, or "Original" when that can't be told), then
/// every other script the converter offers.
class _ScriptChips extends StatelessWidget {
  const _ScriptChips({
    required this.converter,
    required this.sourceScriptId,
    required this.selectedScriptId,
    required this.onTap,
  });

  final ScriptConverter converter;
  final String? sourceScriptId;

  /// Null means the text is shown as written.
  final String? selectedScriptId;
  final ValueChanged<String?> onTap;

  @override
  Widget build(BuildContext context) {
    final source = converter.scriptById(sourceScriptId);
    final picked = activeScriptRow(
      selectedScriptId: selectedScriptId,
      sourceScriptId: sourceScriptId,
    );
    return ReaderSheetChips(
      spacing: 8,
      children: [
        ReaderSheetChip(
          label: source?.label ?? context.l10n.reader_original_label,
          selected: picked == null,
          onTap: () => onTap(null),
        ),
        for (final script in converter.scripts)
          if (script.id != sourceScriptId)
            ReaderSheetChip(
              label: script.label,
              selected: script.id == picked,
              onTap: () => onTap(script.id),
            ),
      ],
    );
  }
}

Future<void> showReaderLanguagesSheet(
  BuildContext context, {
  required ReaderSettingsScope scope,
  required ReaderSlotConfig primaryDisplay,
  String? sourceSample,
  List<ReaderLanguagesText> others = const [],
}) {
  return showReaderSheet<void>(
    context,
    dim: ReaderSheetDim.languages,
    builder:
        (_) => ReaderLanguagesSheet(
          scope: scope,
          primaryDisplay: primaryDisplay,
          sourceSample: sourceSample,
          others: others,
        ),
  );
}
