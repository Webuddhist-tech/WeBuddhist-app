import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_dual_settings_provider.dart';
import 'package:flutter_pecha/features/reader/presentation/utils/reader_secondary_version.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/language_picker_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/script_picker_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/slot_config_card.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_settings/version_picker_sheet.dart';
import 'package:flutter_pecha/shared/widgets/app_toggle_switch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';

class ReaderSettingsScreen extends ConsumerWidget {
  const ReaderSettingsScreen({
    super.key,
    required this.textId,
    this.initialPrimaryDisplay,
    this.asSheet = false,
  });

  final String textId;

  /// Renders as bottom-sheet content (drag handle + title) instead of a page.
  final bool asSheet;

  /// Snapshot of what the reader is currently displaying for the primary
  /// slot, passed in from the reader screen. Used as the display default for
  /// the Main text card when the user hasn't picked a version yet — this is
  /// the explicit, side-effect-free replacement for the previous
  /// "backfill into global settings" mechanism.
  final ReaderSlotConfig? initialPrimaryDisplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerDualSettingsProvider(textId));
    final notifier = ref.read(readerDualSettingsProvider(textId).notifier);
    final isResolvingVersion = ref.watch(
      readerSecondaryResolvingProvider(textId),
    );
    final theme = Theme.of(context);

    final primaryDisplay = _primaryDisplay(ref, settings);
    final title = Text(
      context.l10n.parallel_version,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );

    final body = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SecondaryToggle(
            enabled: settings.secondaryEnabled,
            onChanged: notifier.setSecondaryEnabled,
          ),
          const Divider(height: 32),
          _StaticVersionSection(
            headerLabel: context.l10n.main_version,
            config: primaryDisplay,
            theme: theme,
          ),
          const SizedBox(height: 18),
          SlotConfigCard(
            headerLabel: context.l10n.second_version,
            config: settings.secondary,
            enabled: settings.secondaryEnabled,
            showScriptRow: false,
            isVersionLoading: isResolvingVersion,
            onLanguage: () => _pickLanguage(context, ref, primaryDisplay),
            onVersion: () => _pickVersion(context, ref),
            onScript: () => _pickScript(context, ref, isPrimary: false),
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: settings.secondaryEnabled ? 1.0 : 0.45,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                context.l10n.second_version_msg,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (asSheet) {
      return SafeArea(
        top: false,
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
            const SizedBox(height: 14),
            title,
            Flexible(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: title,
      ),
      body: SafeArea(child: body),
    );
  }

  /// Show the user's explicit pick if they've made one; otherwise fall back
  /// to what the reader is currently displaying. The notifier's
  /// `isPrimaryEdited` flag is the only reliable signal — a user picking the
  /// default values (e.g. "English" when defaults are "English") would
  /// otherwise be indistinguishable from "untouched".
  ReaderSlotConfig _primaryDisplay(
    WidgetRef ref,
    ReaderDualLayoutSettings settings,
  ) {
    final notifier = ref.read(readerDualSettingsProvider(textId).notifier);
    if (notifier.isPrimaryEdited) return settings.primary;
    return initialPrimaryDisplay ?? settings.primary;
  }

  ReaderSlotConfig _secondarySlot(WidgetRef ref) {
    return ref.read(readerDualSettingsProvider(textId)).secondary;
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    ReaderSlotConfig mainConfig,
  ) async {
    final notifier = ref.read(readerDualSettingsProvider(textId).notifier);
    final current = _secondarySlot(ref);

    await showLanguagePickerSheet(
      context,
      textId: textId,
      selectedCode: current.languageCode,
      onSelected: (option) {
        if (option.code == current.languageCode) return;
        // Set the language right away (version cleared); the version is then
        // auto-resolved below once the picker sheet closes.
        notifier.replaceSecondary(
          ReaderSlotConfig(
            languageCode: option.code,
            languageLabel: getLanguageName(option.code, context),
          ),
        );
      },
    );

    // Auto-select a version for the freshly picked language. Skip if the slot
    // is still unset (sheet dismissed) or already has a version.
    final picked = _secondarySlot(ref);
    if (picked.isUnset || picked.versionId != null) return;

    final resolveGeneration = notifier.secondaryResolveGeneration;
    final resolving = ref.read(
      readerSecondaryResolvingProvider(textId).notifier,
    );
    resolving.state = true;
    try {
      await autoSelectSecondaryVersion(
        ref: ref,
        textId: textId,
        slot: picked,
        mainConfig: mainConfig,
        resolveGeneration: resolveGeneration,
      );
    } finally {
      resolving.state = false;
    }
  }

  Future<void> _pickVersion(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(readerDualSettingsProvider(textId).notifier);
    final current = _secondarySlot(ref);

    await showVersionPickerSheet(
      context,
      textId: textId,
      languageCode: current.languageCode,
      languageLabel: current.languageLabel,
      selectedVersionId: current.versionId,
      onSelected: (option) {
        final next = current.copyWith(
          versionId: option.id,
          versionLabel: option.title,
          versionUnavailable: false,
        );
        notifier.replaceSecondary(next);
      },
    );
  }

  Future<void> _pickScript(
    BuildContext context,
    WidgetRef ref, {
    required bool isPrimary,
  }) async {
    final notifier = ref.read(readerDualSettingsProvider(textId).notifier);
    final current = _secondarySlot(ref);

    await showScriptPickerSheet(
      context,
      textId: textId,
      languageCode: current.languageCode,
      languageLabel: current.languageLabel,
      selectedScriptId: current.scriptId,
      onSelected: (option) {
        final next = current.copyWith(
          scriptId: option.id,
          scriptLabel: option.label,
        );
        notifier.replaceSecondary(next);
      },
    );
  }
}

class _SecondaryToggle extends StatelessWidget {
  const _SecondaryToggle({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!enabled),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.show_second_version,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.enable_add_msg,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppToggleSwitch(value: enabled, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// Non-tappable display section for the primary/main version.
/// Shows plain label/value rows with no card border, background, or chevrons.
class _StaticVersionSection extends StatelessWidget {
  const _StaticVersionSection({
    required this.headerLabel,
    required this.config,
    required this.theme,
  });

  final String headerLabel;
  final ReaderSlotConfig config;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            headerLabel.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.3,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _StaticRow(
          label: l10n.language,
          value: config.languageLabel,
          theme: theme,
        ),
        _StaticRow(
          label: l10n.version,
          value: config.versionLabel ?? '—',
          theme: theme,
        ),
      ],
    );
  }
}

class _StaticRow extends StatelessWidget {
  const _StaticRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> openReaderSettings(
  BuildContext context, {
  required String textId,
  ReaderSlotConfig? initialPrimaryDisplay,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: false,
      builder:
          (_) => ReaderSettingsScreen(
            textId: textId,
            initialPrimaryDisplay: initialPrimaryDisplay,
          ),
    ),
  );
}

/// Same settings as [openReaderSettings], shown as a bottom sheet.
Future<void> showReaderSettingsSheet(
  BuildContext context, {
  required String textId,
  ReaderSlotConfig? initialPrimaryDisplay,
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
        (_) => ReaderSettingsScreen(
          textId: textId,
          initialPrimaryDisplay: initialPrimaryDisplay,
          asSheet: true,
        ),
  );
}
