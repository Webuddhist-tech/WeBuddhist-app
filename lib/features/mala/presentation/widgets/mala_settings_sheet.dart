import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/analytics/share_analytics.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/network/connectivity_service.dart'
    show connectivityNotifierProvider;
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/group_accumulation_counts_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_accumulation_selection_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_providers.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/mala_settings_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/mantra_speed_sheet.dart';
import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/presentation/controllers/bookmark_controller.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_pecha/shared/widgets/app_toggle_switch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class MalaSettingsSheet extends ConsumerWidget {
  const MalaSettingsSheet({super.key, required this.mantra});

  final Mantra mantra;

  static Future<void> show(BuildContext context, {required Mantra mantra}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => MalaSettingsSheet(mantra: mantra),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(malaSettingsProvider);
    final settingsNotifier = ref.read(malaSettingsProvider.notifier);
    final isOnline = ref.watch(connectivityNotifierProvider);
    final selection = ref.watch(
      malaAccumulationSelectionProvider(mantra.presetId),
    );
    final isPersonal = selection.isPersonal;
    final counter = ref.watch(malaCounterProvider(mantra));
    final canReset =
        isOnline &&
        !counter.isSeeding &&
        !counter.isResetting &&
        (isPersonal || selection.groupAccumulatorId != null);
    final isBookmarked = ref.watch(
      isBookmarkedProvider(
        BookmarkTarget(
          type: BookmarkType.accumulator,
          sourceId: mantra.presetId,
        ),
      ),
    );
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    const destructiveColor = Color(0xFFB03027);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.goldLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _MalaSettingsSectionHeader(label: l10n.mala_settings_section),
            _MalaSettingsTile(
              icon: AppAssets.speedometer,
              label: l10n.mala_mantra_speed,
              onTap: () => MantraSpeedSheet.show(context),
            ),
            Divider(height: 1, color: dividerColor),
            _MalaSettingsToggleTile(
              icon: AppAssets.speakerSimpleHigh,
              label: l10n.mala_sound,
              value: settings.soundEnabled,
              onChanged: settingsNotifier.setSoundEnabled,
            ),
            Divider(height: 1, color: dividerColor),
            _MalaSettingsToggleTile(
              icon: AppAssets.vibrate,
              label: l10n.mala_vibration,
              value: settings.vibrationEnabled,
              onChanged: settingsNotifier.setVibrationEnabled,
            ),
            Divider(height: 1, color: dividerColor),
            _MalaSettingsSectionHeader(label: l10n.mala_others_section),
            if (isPersonal)
              _MalaSettingsTile(
                icon: AppAssets.plus,
                label: l10n.mala_add_to_practice,
                enabled: isPersonal,
                onTap: () => _onAddToPractice(context),
              ),
            if (isPersonal) Divider(height: 1, color: dividerColor),
            if (isPersonal)
              _MalaSettingsTile(
                icon:
                    isBookmarked
                        ? AppAssets.bookmarkSimpleFill
                        : AppAssets.bookmarkSimple,
                label: l10n.mala_add_to_bookmark,
                enabled: isPersonal,
                onTap: () => _onToggleBookmark(context, ref),
              ),
            if (isPersonal) Divider(height: 1, color: dividerColor),
            _MalaSettingsTile(
              icon: AppAssets.readerShare,
              label: l10n.share,
              onTap: () => _onShare(context),
            ),
            Divider(height: 1, color: dividerColor),
            _MalaSettingsTile(
              icon: AppAssets.arrowCounterClockwise,
              label: l10n.mala_reset_count,
              labelColor: destructiveColor,
              iconColor: destructiveColor,
              enabled: canReset,
              onTap: () => _onResetCount(context, ref),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _onShare(BuildContext context) async {
    final shareMessage = context.l10n.share_mala_message;
    final sharePositionOrigin = getSharePositionOrigin(context: context);
    final longUrl =
        DeepLinkUrlBuilder.malaLink(presetId: mantra.presetId).toString();
    final shareUrl = await resolveShareUrl(context, longUrl);
    if (!context.mounted) return;

    // Read before pop: the sheet's context is gone once it closes.
    final shareAnalytics = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(shareAnalyticsProvider);
    Navigator.of(context).pop();
    final result = await SharePlus.instance.share(
      ShareParams(
        text: '$shareMessage\n\n$shareUrl',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    if (ShareAnalytics.wasUsed(result)) {
      shareAnalytics.contentShared(
        surface: ShareSurface.mala,
        targetId: mantra.presetId,
        format: 'text',
      );
    }
  }

  void _onAddToPractice(BuildContext context) {
    // Mala is login-gated, so the user is always authenticated here; the
    // edit-routine route's auth guard is a backstop. Capture the router before
    // dismissing the sheet, then open the routine editor with the mala
    // injected as an ACCUMULATOR session.
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.pushNamed('edit-routine', extra: {'initialMantra': mantra});
  }

  Future<void> _onToggleBookmark(BuildContext context, WidgetRef ref) async {
    final language = ref.read(contentLanguageProvider);
    final navigator = Navigator.of(context);

    final didToggle = await BookmarkController(
      ref: ref,
      context: context,
    ).toggleMala(mantra.presetId, name: mantra.displayTitle(language));

    if (context.mounted && didToggle) navigator.pop();
  }

  Future<void> _onResetCount(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final selection = ref.read(
      malaAccumulationSelectionProvider(mantra.presetId),
    );

    final result = await showDestructiveConfirmationDialog(
      context,
      title: l10n.mala_reset_title,
      message: l10n.mala_reset_count_confirm,
      confirmLabel: l10n.mala_reset_confirm,
      cancelLabel: l10n.cancel,
      barrierDismissible: false,
      onConfirmed: () async {
        HapticFeedback.mediumImpact();
        if (selection.isPersonal) {
          return ref.read(malaCounterProvider(mantra).notifier).resetCount();
        }
        final groupAccumulatorId = selection.groupAccumulatorId;
        if (groupAccumulatorId == null) return false;
        return ref
            .read(groupAccumulationCountsProvider(mantra.presetId).notifier)
            .resetCount(groupAccumulatorId: groupAccumulatorId);
      },
    );
    if (!context.mounted) return;
    if (result == true) {
      if (!selection.isPersonal) {
        final groupId = selection.groupAccumulatorId;
        if (groupId != null) {
          ref.invalidate(groupAccumulatorDetailProvider(groupId));
        }
        // Refresh session counts from detail API; post-reset guard prevents stale totals.
        ref.invalidate(joinedGroupUserCountsProvider(mantra.presetId));
        // Refresh lifetime totals for the accumulations sheet.
        ref.invalidate(joinedAccumulatorGroupsProvider(mantra.presetId));
      }
      Navigator.of(context).pop();
    } else if (result == false) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.something_went_wrong)),
      );
    }
  }
}

class _MalaSettingsSectionHeader extends StatelessWidget {
  const _MalaSettingsSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _MalaSettingsTile extends StatelessWidget {
  const _MalaSettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = labelColor ?? theme.colorScheme.onSurface;

    return Opacity(
      opacity: enabled ? 1.0 : 0.38,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 24, color: iconColor ?? foreground),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MalaSettingsToggleTile extends StatelessWidget {
  const _MalaSettingsToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: foreground),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
          ),
          AppToggleSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
