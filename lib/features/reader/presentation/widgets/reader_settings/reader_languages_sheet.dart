import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_language_option.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_settings_scope.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_version_detail.dart';
import 'package:flutter_pecha/features/reader/domain/transliteration/script_converter.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_script_preference_provider.dart'
    show transliterationServiceProvider;
import 'package:flutter_pecha/features/reader/presentation/providers/reader_settings_providers.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_secondary_version.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/picker_state_views.dart';
import 'package:flutter_pecha/shared/widgets/app_toggle_switch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Languages drawer: an Original section (with a script dropdown when the
/// text's language can be transliterated on the phone) plus a Translation
/// toggle with an inline language › versions dropdown.
class ReaderLanguagesSheet extends ConsumerStatefulWidget {
  const ReaderLanguagesSheet({
    super.key,
    required this.scope,
    required this.primaryDisplay,
    this.sourceSample,
  });

  /// The text and context whose settings this sheet edits.
  final ReaderSettingsScope scope;
  final ReaderSlotConfig primaryDisplay;

  /// Plain text lifted from the loaded segments, used to tell which script
  /// the original is written in. Null (or empty) leaves the script unknown,
  /// which only costs the first row its name. Never the title: titles are
  /// routinely romanised even when the body is not.
  final String? sourceSample;

  @override
  ConsumerState<ReaderLanguagesSheet> createState() =>
      _ReaderLanguagesSheetState();
}

class _ReaderLanguagesSheetState extends ConsumerState<ReaderLanguagesSheet> {
  bool _expanded = false;
  bool _originalExpanded = false;
  String? _expandedLanguage;
  bool _filling = false;

  ReaderSettingsScope get _scope => widget.scope;

  ReaderDualSettingsNotifier get _notifier =>
      ref.read(readerDualSettingsProvider(_scope).notifier);

  ReaderSlotConfig get _secondary =>
      ref.read(readerDualSettingsProvider(_scope)).secondary;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(readerDualSettingsProvider(_scope));
    // Open the dropdown right away when nothing is picked yet.
    _expanded = settings.secondaryEnabled && settings.secondary.versionId == null;
    if (!settings.secondary.isUnset) {
      _expandedLanguage = settings.secondary.languageCode;
    }
  }

  ReaderSlotConfig _primary() {
    if (_notifier.isPrimaryEdited) {
      return ref.read(readerDualSettingsProvider(_scope)).primary;
    }
    return widget.primaryDisplay;
  }

  Future<void> _onToggle(bool value) async {
    HapticFeedback.lightImpact();
    _notifier.setSecondaryEnabled(value);
    if (!value) {
      setState(() => _expanded = false);
      return;
    }
    if (_secondary.versionId != null) return;

    setState(() => _filling = true);
    final primary = _primary();
    bool filled = false;
    try {
      filled = await fillSettingsLanguageSecondary(
        ref: ref,
        context: context,
        scope: _scope,
        sourceLanguage: primary.languageCode,
        sourceVersionId: primary.versionId,
      );
    } finally {
      if (mounted) setState(() => _filling = false);
    }
    if (!mounted) return;
    setState(() {
      _expanded = !filled;
      if (filled) _expandedLanguage = _secondary.languageCode;
    });
  }

  Future<void> _onLanguageTap(ReaderLanguageOption option) async {
    HapticFeedback.selectionClick();
    final wasOpen = _expandedLanguage == option.code;
    setState(() => _expandedLanguage = wasOpen ? null : option.code);
    if (wasOpen) return;

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
    _notifier.rememberTranslationLanguage(option.code);
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

  void _onVersionTap(ReaderLanguageOption language, ReaderVersionDetail v) {
    HapticFeedback.selectionClick();
    _notifier.rememberTranslationLanguage(language.code);
    _notifier.replaceSecondary(
      ReaderSlotConfig(
        languageCode: language.code,
        languageLabel: getLanguageName(language.code, context),
        versionId: v.id,
        versionLabel: v.title,
      ),
    );
  }

  String _translationLabel(ReaderSlotConfig slot) {
    final l10n = context.l10n;
    if (slot.isUnset) return l10n.select_language;
    if (slot.versionUnavailable) {
      return '${slot.languageLabel} (${l10n.version_not_available})';
    }
    final version = slot.versionLabel;
    if (version == null || version.isEmpty) return slot.languageLabel;
    return '${slot.languageLabel} ($version)';
  }

  /// The Original field names the script on screen: the picked one, else
  /// the one the text is written in. Languages with no converter keep the
  /// translation-style label ("English (title)").
  String _originalLabel(
    ReaderSlotConfig primary,
    ScriptConverter? converter,
    String? sourceScriptId,
    String? selectedScriptId,
  ) {
    if (converter == null) return _translationLabel(primary);
    final script =
        converter.scriptById(selectedScriptId) ??
        converter.scriptById(sourceScriptId);
    if (script == null) return _translationLabel(primary);
    return script.label;
  }

  void _onScriptTap(String languageCode, String? scriptId) {
    HapticFeedback.selectionClick();
    _notifier.setOriginalScript(languageCode, scriptId);
  }

  /// Hiding the original needs a translation on screen, so it switches the
  /// translation on and picks a version the way the Translation switch does.
  Future<void> _onOriginalToggle(bool visible) async {
    HapticFeedback.lightImpact();
    _notifier.setOriginalVisible(visible);
    if (visible || _secondary.versionId != null) return;
    await _onToggle(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
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
    // One of the two layers is always on: the original stays on screen (and
    // its switch on) until a translation is actually showing.
    final secondaryActive = enabled && settings.secondary.versionId != null;
    final originalShown = settings.originalVisible || !secondaryActive;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: ReaderPanelConstants.dragHandleWidth,
              height: ReaderPanelConstants.dragHandleHeight,
              decoration: BoxDecoration(
                color: ReaderPanelConstants.dragHandleColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(AppAssets.arrowLeft),
                    tooltip: l10n.back,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Text(
                    l10n.reader_languages_title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      label: l10n.reader_original_label,
                      trailing: AppToggleSwitch(
                        value: originalShown,
                        onChanged: busy ? (_) {} : _onOriginalToggle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: originalShown ? 1.0 : 0.45,
                      child: _DropdownField(
                        label: _originalLabel(
                          primary,
                          converter,
                          sourceScript,
                          selectedScript,
                        ),
                        enabled: converter != null && originalShown,
                        showChevron: converter != null,
                        expanded: _originalExpanded,
                        onTap:
                            () => setState(
                              () => _originalExpanded = !_originalExpanded,
                            ),
                      ),
                    ),
                    if (converter != null && originalShown && _originalExpanded)
                      _ScriptList(
                        converter: converter,
                        sourceScriptId: sourceScript,
                        selectedScriptId: selectedScript,
                        onTap: (id) => _onScriptTap(primary.languageCode, id),
                      ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      label: l10n.reader_translation_label,
                      trailing: AppToggleSwitch(
                        value: enabled,
                        onChanged: busy ? (_) {} : _onToggle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: enabled ? 1.0 : 0.45,
                      child: _DropdownField(
                        label: _translationLabel(settings.secondary),
                        enabled: enabled && !busy,
                        expanded: _expanded,
                        isLoading: busy,
                        onTap: () => setState(() => _expanded = !_expanded),
                      ),
                    ),
                    if (enabled && _expanded)
                      _LanguageTree(
                        textId: _scope.textId,
                        secondary: settings.secondary,
                        expandedLanguage: _expandedLanguage,
                        onLanguageTap: busy ? null : _onLanguageTap,
                        onVersionTap: _onVersionTap,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.enabled,
    this.expanded = false,
    this.showChevron = true,
    this.isLoading = false,
    this.onTap,
  });

  final String label;
  final bool enabled;
  final bool expanded;
  final bool showChevron;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.onSurface;
    return Material(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(color: accent),
                ),
              ),
              if (isLoading) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                ),
              ] else if (showChevron) ...[
                const SizedBox(width: 8),
                Icon(
                  expanded ? AppAssets.caretUp : AppAssets.caretDown,
                  size: 18,
                  color: accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTree extends ConsumerWidget {
  const _LanguageTree({
    required this.textId,
    required this.secondary,
    required this.expandedLanguage,
    required this.onLanguageTap,
    required this.onVersionTap,
  });

  final String textId;
  final ReaderSlotConfig secondary;
  final String? expandedLanguage;
  final ValueChanged<ReaderLanguageOption>? onLanguageTap;
  final void Function(ReaderLanguageOption, ReaderVersionDetail) onVersionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final asyncLangs = ref.watch(readerLanguagesProvider(textId));

    return asyncLangs.when(
      loading: () => const PickerLoading(),
      error:
          (_, __) => PickerError(
            message: l10n.reader_languages_load_error,
            onRetry: () => ref.invalidate(readerLanguagesProvider(textId)),
          ),
      data: (langs) {
        if (langs.isEmpty) {
          return PickerEmpty(message: l10n.reader_no_languages);
        }
        return Padding(
          padding: const EdgeInsets.only(top: 4, left: 16),
          child: Column(
            children: [
              for (final lang in langs) ...[
                _LanguageRow(
                  option: lang,
                  isActive: readerLanguagesMatch(
                    lang.code,
                    secondary.languageCode,
                  ),
                  isOpen: expandedLanguage == lang.code,
                  onTap:
                      onLanguageTap == null ? null : () => onLanguageTap!(lang),
                ),
                if (expandedLanguage == lang.code)
                  _VersionList(
                    textId: textId,
                    language: lang,
                    selectedVersionId: secondary.versionId,
                    onTap: (v) => onVersionTap(lang, v),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.option,
    required this.isActive,
    required this.isOpen,
    required this.onTap,
  });

  final ReaderLanguageOption option;
  final bool isActive;
  final bool isOpen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.onSurface;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    getLanguageName(option.code, context),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isActive ? accent : null,
                      fontWeight: isActive ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                if (isOpen)
                  Icon(AppAssets.caretUp, size: 16, color: accent),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
      ],
    );
  }
}

class _VersionList extends ConsumerWidget {
  const _VersionList({
    required this.textId,
    required this.language,
    required this.selectedVersionId,
    required this.onTap,
  });

  final String textId;
  final ReaderLanguageOption language;
  final String? selectedVersionId;
  final ValueChanged<ReaderVersionDetail> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = theme.colorScheme.onSurface;
    final query = ReaderLanguageQuery(textId: textId, language: language.code);
    final asyncVersions = ref.watch(readerVersionsProvider(query));

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: asyncVersions.when(
        loading: () => const PickerLoading(),
        error:
            (_, __) => PickerError(
              message: l10n.reader_versions_load_error,
              onRetry: () => ref.invalidate(readerVersionsProvider(query)),
            ),
        data: (versions) {
          if (versions.isEmpty) {
            return PickerEmpty(
              message: l10n.reader_no_versions_in_language(
                getLanguageName(language.code, context),
              ),
            );
          }
          return Column(
            children: [
              for (final v in versions) ...[
                InkWell(
                  onTap: () => onTap(v),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            v.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: v.id == selectedVersionId ? accent : null,
                              fontWeight:
                                  v.id == selectedVersionId
                                      ? FontWeight.w600
                                      : null,
                            ),
                          ),
                        ),
                        if (v.id == selectedVersionId)
                          Icon(Icons.check, size: 18, color: accent),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: theme.dividerColor),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Which row of [_ScriptList] is ticked, given the user's pick and the script
/// the text is written in.
///
/// The source script has no row of its own - it *is* the "as written" row -
/// so a pick naming it is the same choice, and passing it through would leave
/// the list with nothing ticked (a Sinhala pick opened on a Sinhala text).
@visibleForTesting
String? activeScriptRow({
  required String? selectedScriptId,
  required String? sourceScriptId,
}) => selectedScriptId == sourceScriptId ? null : selectedScriptId;

/// Scripts the Original text can be shown in. The first row is the text as
/// written (its own script, or "Original" when that can't be told), followed
/// by every other script the converter offers.
class _ScriptList extends StatelessWidget {
  const _ScriptList({
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
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 16),
      child: Column(
        children: [
          _ScriptRow(
            label:
                source == null
                    ? context.l10n.reader_original_label
                    : source.label,
            isActive: picked == null,
            onTap: () => onTap(null),
          ),
          for (final script in converter.scripts)
            if (script.id != sourceScriptId)
              _ScriptRow(
                label: script.label,
                isActive: script.id == picked,
                onTap: () => onTap(script.id),
              ),
        ],
      ),
    );
  }
}

class _ScriptRow extends StatelessWidget {
  const _ScriptRow({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.onSurface;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isActive ? accent : null,
                      fontWeight: isActive ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                if (isActive) Icon(AppAssets.check, size: 18, color: accent),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
      ],
    );
  }
}

Future<void> showReaderLanguagesSheet(
  BuildContext context, {
  required ReaderSettingsScope scope,
  required ReaderSlotConfig primaryDisplay,
  String? sourceSample,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ReaderPanelConstants.topRadius),
      ),
    ),
    isScrollControlled: true,
    builder:
        (_) => ReaderLanguagesSheet(
          scope: scope,
          primaryDisplay: primaryDisplay,
          sourceSample: sourceSample,
        ),
  );
}
