import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_notification_preferences_provider.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the member did in [GroupNotificationSettingsDrawer] before it closed.
/// The caller acts on it after the sheet is fully gone, so no navigation ever
/// runs from the sheet's own context.
enum GroupNotificationSheetResult {
  /// The member confirmed leaving and the leave request succeeded.
  left,

  /// The member tapped "Turn on" under the master-switch notice.
  openNotificationSettings,
}

/// Shows the member sheet for [profile] from the space page's ⋮ and acts on
/// its result from [context], after the sheet has closed, so no route is
/// pushed from inside a modal that is on its way out.
///
/// A Page's sheet holds only the way out: following a Page is not a
/// membership, and the backend rejects per-group notification settings for
/// followers.
Future<void> openGroupMemberMenu(
  BuildContext context,
  GroupProfile profile, {
  required GroupFollowKey followKey,
}) async {
  final result = await GroupNotificationSettingsDrawer.show(
    context,
    profile,
    followKey: followKey,
    showNotificationSettings: !profile.groupType.isPage,
  );
  if (!context.mounted) return;
  if (result == GroupNotificationSheetResult.openNotificationSettings) {
    // The space page is a root-pushed route above the /home shell, and
    // AppRoutes.notifications lives inside that shell. Pushing it through
    // go_router from here makes the router insert a second /home shell page
    // and trip its duplicate page key assertion, so the screen goes on the
    // root navigator as a pageless route instead. Its own back button uses
    // context.pop(), which go_router resolves to this route.
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'notifications'),
        builder: (_) => const NotificationSettingsScreen(),
      ),
    );
  }
}

/// Member menu behind the space page's ⋮: per-space push toggles and the way
/// out of the space.
///
/// - Space chat: pushes for chat messages.
/// - Space content: pushes for new posts, new events and reminders for events
///   the member joined.
///
/// Both toggles are greyed out while the app's master notification switch is
/// off or the OS permission is missing (`NotificationState.notificationsOn`),
/// since nothing is delivered in that state anyway; their saved values are
/// untouched and come back once notifications are on again.
///
/// With [showNotificationSettings] false (a Page) only the leave row shows,
/// and the per-group preferences are never fetched.
class GroupNotificationSettingsDrawer extends ConsumerWidget {
  final GroupProfile profile;
  final GroupFollowKey followKey;
  final bool showNotificationSettings;

  const GroupNotificationSettingsDrawer({
    super.key,
    required this.profile,
    required this.followKey,
    this.showNotificationSettings = true,
  });

  /// Resolves to what the member did, or null when the sheet was dismissed.
  static Future<GroupNotificationSheetResult?> show(
    BuildContext context,
    GroupProfile profile, {
    required GroupFollowKey followKey,
    bool showNotificationSettings = true,
  }) {
    return showModalBottomSheet<GroupNotificationSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder:
          (_) => GroupNotificationSettingsDrawer(
            profile: profile,
            followKey: followKey,
            showNotificationSettings: showNotificationSettings,
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showNotificationSettings) {
      return _SheetFrame(
        children: [
          const SizedBox(height: 8),
          _LeaveGroupRow(onTap: () => _confirmLeave(context, ref)),
          const SizedBox(height: 8),
        ],
      );
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final groupId = profile.id;

    final prefsState = ref.watch(groupNotificationPreferencesProvider(groupId));
    final appOn = ref.watch(
      notificationProvider.select((s) => s.notificationsOn),
    );
    final notifier = ref.read(
      groupNotificationPreferencesProvider(groupId).notifier,
    );

    // A reverted toggle is the visible cue; the snackbar says why.
    ref.listen(groupNotificationPreferencesProvider(groupId), (prev, next) {
      final failure = next.lastFailure;
      if (failure == null || identical(failure, prev?.lastFailure)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.group_notifications_update_failed),
          backgroundColor: AppColors.error,
        ),
      );
    });

    final preferences = prefsState.preferences;
    final dividerColor = theme.colorScheme.onSurface.withValues(alpha: 0.12);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return _SheetFrame(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.group_notifications_title,
            strutStyle: context.tibetanStrutStyle(20),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        if (!appOn) ...[
          const SizedBox(height: 8),
          _MasterOffNotice(color: mutedColor),
        ],
        const SizedBox(height: 4),
        if (prefsState.loadFailure != null)
          // Never show defaults as if they were saved choices.
          _LoadFailedRow(color: mutedColor, onRetry: notifier.retry)
        else ...[
          _ToggleRow(
            icon: AppAssets.chatCircleDots,
            label: l10n.group_notifications_chat,
            value: appOn && preferences.chat,
            enabled: appOn,
            loading: prefsState.isLoading,
            onChanged: notifier.setChat,
          ),
          _ToggleRow(
            icon: AppAssets.rows,
            label: l10n.group_notifications_content,
            value: appOn && preferences.content,
            enabled: appOn,
            loading: prefsState.isLoading,
            onChanged: notifier.setContent,
          ),
        ],
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 1, color: dividerColor),
        _LeaveGroupRow(onTap: () => _confirmLeave(context, ref)),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;

    final left = await showDestructiveConfirmationDialog(
      context,
      title: l10n.group_leave_space_confirm_title,
      message: l10n.group_leave_confirm_message,
      confirmLabel: l10n.group_leave_space,
      onConfirmed:
          () => ref
              .read(groupFollowProvider(followKey).notifier)
              .unfollow(connectGroup: profile),
    );
    if (!context.mounted) return;

    if (left == true) {
      Navigator.of(context).pop(GroupNotificationSheetResult.left);
      return;
    }
    if (left == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.group_leave_space_failed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// Rounded sheet surface with the drag handle; [children] go below it.
class _SheetFrame extends StatelessWidget {
  final List<Widget> children;

  const _SheetFrame({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool enabled;

  /// Stored values not read yet: the switch is replaced by a spinner so a
  /// default never shows and then snaps.
  final bool loading;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentColor =
        enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return MergeSemantics(
      child: InkWell(
        onTap: enabled && !loading ? () => onChanged(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 26, color: contentColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  strutStyle: context.tibetanStrutStyle(17),
                  style: TextStyle(fontSize: 17, color: contentColor),
                ),
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Switch.adaptive(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                  activeTrackColor: AppColors.brandblue,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MasterOffNotice extends StatelessWidget {
  final Color color;

  const _MasterOffNotice({required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Icon(AppAssets.bellSlash, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.group_notifications_master_off,
              strutStyle: context.tibetanStrutStyle(14),
              style: TextStyle(fontSize: 14, color: color),
            ),
          ),
          TextButton(
            // The profile page navigates once the sheet has closed.
            onPressed:
                () => Navigator.of(
                  context,
                ).pop(GroupNotificationSheetResult.openNotificationSettings),
            child: Text(l10n.group_notifications_open_settings),
          ),
        ],
      ),
    );
  }
}

class _LoadFailedRow extends StatelessWidget {
  final Color color;
  final VoidCallback onRetry;

  const _LoadFailedRow({required this.color, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
      child: Row(
        children: [
          Icon(AppAssets.bellSlash, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.group_notifications_load_failed,
              strutStyle: context.tibetanStrutStyle(14),
              style: TextStyle(fontSize: 14, color: color),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

class _LeaveGroupRow extends StatelessWidget {
  final VoidCallback onTap;

  const _LeaveGroupRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const color = AppColors.error;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          children: [
            const Icon(AppAssets.signOut, size: 26, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                l10n.group_leave_space,
                strutStyle: context.tibetanStrutStyle(17),
                style: const TextStyle(fontSize: 17, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
