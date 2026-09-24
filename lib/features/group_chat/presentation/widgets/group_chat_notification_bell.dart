import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_notification_bell.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_notification_preferences_provider.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chat header bell: mutes or unmutes this group's chat pushes in one tap.
///
/// Shares [groupNotificationPreferencesProvider] with the profile's member
/// sheet, so a flip on either side shows on the other. Watching it here also
/// keeps the auto-disposed notifier alive for as long as the chat is open.
class GroupChatNotificationBell extends ConsumerWidget {
  const GroupChatNotificationBell({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = groupNotificationPreferencesProvider(groupId);
    final prefs = ref.watch(provider);
    final masterOn = ref.watch(
      notificationProvider.select((s) => s.appMasterEnabled),
    );
    final bell = chatBellStateFor(prefs, masterOn: masterOn);

    // A reverted bell is the visible cue; the snackbar says why. Skipped while
    // the profile sheet sits over the chat, which reports the same failure.
    ref.listen(provider, (prev, next) {
      final failure = next.lastFailure;
      if (failure == null || identical(failure, prev?.lastFailure)) return;
      if (ModalRoute.of(context)?.isCurrent == false) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.group_notifications_update_failed),
            backgroundColor: AppColors.error,
          ),
        );
    });

    final muted = bell == ChatBellState.off || bell == ChatBellState.appOff;

    return IconButton(
      icon: Icon(muted ? AppAssets.bellSlash : AppAssets.bell),
      tooltip:
          muted
              ? l10n.group_chat_unmute_notifications
              : l10n.group_chat_mute_notifications,
      onPressed: switch (bell) {
        ChatBellState.loading => null,
        ChatBellState.unavailable => ref.read(provider.notifier).retry,
        ChatBellState.appOff => () => _explainAppOff(context),
        ChatBellState.on => () => _setChat(context, ref, false),
        ChatBellState.off => () => _setChat(context, ref, true),
      },
    );
  }

  /// Confirms only once the save lands: a failure reverts the bell and the
  /// listener in [build] reports it instead.
  Future<void> _setChat(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final l10n = context.l10n;
    final provider = groupNotificationPreferencesProvider(groupId);
    final saved = await ref.read(provider.notifier).setChat(enabled);
    if (!saved || !context.mounted) return;
    // A later tap may have flipped it back before this save settled; that
    // tap's own confirmation covers it.
    if (ref.read(provider).preferences.chat != enabled) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? l10n.group_chat_notifications_unmuted
                : l10n.group_chat_notifications_muted,
          ),
        ),
      );
  }

  /// A group toggle has no effect while the app's master switch is off, so
  /// say so and offer the settings screen rather than flipping it silently.
  void _explainAppOff(BuildContext context) {
    final l10n = context.l10n;
    final navigator = Navigator.of(context, rootNavigator: true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.group_notifications_master_off),
          action: SnackBarAction(
            label: l10n.group_notifications_open_settings,
            // Pageless on the root navigator, for the reason given in
            // `_openMemberMenu` in group_profile_body.dart: a go_router push
            // from a root-level route would duplicate the /home shell page.
            onPressed:
                () => navigator.push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                ),
          ),
        ),
      );
  }
}
