import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_preferences.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_preferences_provider.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_pecha/features/notifications/presentation/widgets/notification_switch_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Push choices for prayer requests, opened from the prayer requests sheet's
/// ⋮ menu and stacked on top of it; its back arrow returns to the list.
///
/// The two switches are the account-wide ones the notification settings
/// screen also shows, so they cover prayer requests from every event and
/// space, not just the one whose sheet is open. While the app's master switch is off or
/// the OS permission is missing they are greyed out; their saved values are
/// untouched.
class PrayerNotificationSettingsSheet extends ConsumerWidget {
  const PrayerNotificationSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const PrayerNotificationSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final state = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);
    final rowsOn = ref.watch(
      notificationProvider.select((s) => s.notificationsOn),
    );

    // A reverted switch is the visible cue; the snackbar says why.
    ref.listen(notificationPreferencesProvider, (prev, next) {
      final failure = next.lastFailure;
      if (failure == null || identical(failure, prev?.lastFailure)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.group_notifications_update_failed),
          backgroundColor: AppColors.error,
        ),
      );
    });

    Widget switchRow(ConnectNotificationToggle toggle, String label) {
      return NotificationSwitchRow(
        label: label,
        value: rowsOn && state.preferences.of(toggle),
        enabled: rowsOn,
        loading: state.isLoading,
        onChanged: (enabled) => notifier.set(toggle, enabled),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(isDark: isDark),
            const SizedBox(height: 8),
            if (!rowsOn) _Notice(text: l10n.group_notifications_master_off),
            if (state.loadFailure != null)
              // Never show defaults as if they were saved choices.
              _Notice(
                text: l10n.group_notifications_load_failed,
                action: TextButton(
                  onPressed: notifier.retry,
                  child: Text(l10n.retry),
                ),
              )
            else ...[
              switchRow(
                ConnectNotificationToggle.prayerReceived,
                l10n.notification_row_my_prayer_requests,
              ),
              switchRow(
                ConnectNotificationToggle.prayerRequest,
                l10n.notification_row_others_prayer_requests,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Grey band with the drag handle and "← Notifications", matching the
/// prayer requests sheet underneath.
class _Header extends StatelessWidget {
  const _Header({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 16, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(AppAssets.arrowLeft),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    context.l10n.group_notifications_title,
                    strutStyle: context.tibetanStrutStyle(17, compact: true),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    final action = this.action;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, action == null ? 20 : 8, 8),
      child: Row(
        children: [
          Icon(AppAssets.bellSlash, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              strutStyle: context.tibetanStrutStyle(14),
              style: TextStyle(fontSize: 14, color: color),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}
