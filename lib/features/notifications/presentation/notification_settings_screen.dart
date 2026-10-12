import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_pecha/shared/widgets/app_toggle_switch.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/notifications/application/notification_sync_engine.dart';
import 'package:flutter_pecha/features/notifications/data/channels/notification_channels.dart';
import 'package:flutter_pecha/features/notifications/domain/entities/notification_preferences.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_preferences_provider.dart';
import 'package:flutter_pecha/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_pecha/features/notifications/presentation/widgets/notification_switch_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});
  static const String routeName = '/notifications';

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool _isSchedulingTest = false;
  static const int _testNotifId = 9999;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationProvider.notifier).refreshStatus().then((_) {
        // Engine short-circuits when master is off or permission is missing.
        ref
            .read(notificationSyncEngineProvider)
            .sync(trigger: SyncTrigger.appResume);
      });
    }
  }

  // ── Toggle handlers ────────────────────────────────────────────────────────

  Future<void> _toggleMaster(bool enable) async {
    final result = await ref
        .read(notificationProvider.notifier)
        .toggleMaster(enable);
    if (!mounted) return;
    switch (result) {
      case NotificationToggleResult.permissionDenied:
        _snack(
          AppLocalizations.of(context)!.notification_snack_permission_denied,
        );
        await openAppSettings();
      case NotificationToggleResult.error:
        _snack(AppLocalizations.of(context)!.something_went_wrong);
      case NotificationToggleResult.success:
        break;
    }
  }

  // Permission comes back through refreshStatus on resume.
  Future<void> _openSystemSettings() async {
    await openAppSettings();
  }

  Future<void> _toggleRoutine(bool enable) async {
    final result = await ref
        .read(notificationProvider.notifier)
        .toggleRoutine(enable);
    if (!mounted) return;
    if (result == NotificationToggleResult.error) {
      _snack(AppLocalizations.of(context)!.something_went_wrong);
    }
  }

  Future<void> _toggleRecitation(bool enable) async {
    final result = await ref
        .read(notificationProvider.notifier)
        .toggleRecitation(enable);
    if (!mounted) return;
    if (result == NotificationToggleResult.error) {
      _snack(AppLocalizations.of(context)!.something_went_wrong);
    }
  }

  Future<void> _togglePractice(bool enable) async {
    final result = await ref
        .read(notificationProvider.notifier)
        .togglePractice(enable);
    if (!mounted) return;
    if (result == NotificationToggleResult.error) {
      _snack(AppLocalizations.of(context)!.something_went_wrong);
    }
  }

  Future<void> _toggleTimer(bool enable) async {
    final result =
        await ref.read(notificationProvider.notifier).toggleTimer(enable);
    if (!mounted) return;
    if (result == NotificationToggleResult.error) {
      _snack(AppLocalizations.of(context)!.something_went_wrong);
    }
  }

  Future<void> _toggleExactAlarms(bool enable) async {
    if (enable) {
      await ref.read(notificationServiceProvider).openExactAlarmSettings();
    } else {
      _snack(
        AppLocalizations.of(
          context,
        )!.notification_snack_disable_alarms_in_settings,
      );
      await openAppSettings();
    }
  }

  Future<void> _scheduleTestNotification() async {
    if (!ref.read(notificationProvider).appMasterEnabled) {
      _snack('Notifications are disabled — turn them on first.');
      return;
    }
    final service = ref.read(notificationServiceProvider);
    if (!service.isInitialized) {
      _snack('Notification service not ready.');
      return;
    }
    setState(() => _isSchedulingTest = true);
    try {
      await service.notificationsPlugin.cancel(_testNotifId);
      final at = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 4));
      await service.notificationsPlugin.zonedSchedule(
        _testNotifId,
        'Routine Notification Test',
        'Fires at ${_hhmm(at)} — custom sound test',
        at,
        NotificationChannels.routineBlockDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      _snack('Test scheduled for ${_hhmm(at)} — close the app to verify.');
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _isSchedulingTest = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _hhmm(tz.TZDateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final auth = ref.watch(authProvider);
    final signedIn = auth.isLoggedIn && !auth.isGuest;
    final localizations = AppLocalizations.of(context)!;

    // Nothing is delivered with master off or the OS permission missing, so
    // every row greys out and reads off; the saved values are untouched and
    // come back once both are on again.
    final rowsOn = state.notificationsOn;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        centerTitle: true,
        title: Text(
          localizations.group_notifications_title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body:
          state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  // Not a lazy ListView: the Connect section must stay mounted
                  // while scrolled away, or its preferences reload on return.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MasterCard(
                        title: localizations.notification_allow_title,
                        subtitle:
                            !state.appMasterEnabled
                                ? localizations.notification_allow_subtitle_off
                                : state.hasSystemPermission
                                ? localizations.notification_allow_subtitle_on
                                : localizations
                                    .notification_allow_subtitle_disabled,
                        value: state.appMasterEnabled,
                        onChanged: _toggleMaster,
                        // "Permission needed. Tap to grant in Settings": a tap
                        // on the card does that rather than switching master
                        // off. The switch itself still toggles.
                        onTap:
                            state.appMasterEnabled && !state.hasSystemPermission
                                ? _openSystemSettings
                                : null,
                      ),

                      // ── Practice: local reminders ─────────────────────────
                      _SectionHeader(
                        label: localizations.notification_section_practice,
                        enabled: rowsOn,
                      ),
                      _SettingsCard(
                        children: [
                          NotificationSwitchRow(
                            label: localizations.notification_row_plans,
                            value: rowsOn && state.appRoutineEnabled,
                            enabled: rowsOn,
                            onChanged: _toggleRoutine,
                          ),
                          NotificationSwitchRow(
                            label: localizations.notification_row_chants,
                            value: rowsOn && state.appRecitationEnabled,
                            enabled: rowsOn,
                            onChanged: _toggleRecitation,
                          ),
                          NotificationSwitchRow(
                            label: localizations.notification_row_mala,
                            value: rowsOn && state.appPracticeEnabled,
                            enabled: rowsOn,
                            onChanged: _togglePractice,
                          ),
                          NotificationSwitchRow(
                            label: localizations.notification_row_timer,
                            value: rowsOn && state.appTimerEnabled,
                            enabled: rowsOn,
                            onChanged: _toggleTimer,
                          ),
                        ],
                      ),

                      // ── Connect: server-side, needs an account ────────────
                      if (signedIn) _ConnectSection(rowsOn: rowsOn),
                    ],
                  ),
                ),
              ),
    );
  }
}

/// The Connect header and card. Built only for signed-in users, so the
/// account-wide preferences are never fetched for a guest.
class _ConnectSection extends ConsumerWidget {
  const _ConnectSection({required this.rowsOn});

  final bool rowsOn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);

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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          label: l10n.notification_section_connect,
          enabled: rowsOn,
        ),
        _SettingsCard(
          children:
              state.loadFailure != null
                  // Never show defaults as if they were saved choices.
                  ? [_LoadFailedRow(onRetry: notifier.retry)]
                  : [
                    switchRow(
                      ConnectNotificationToggle.groupPosts,
                      l10n.notification_row_group_posts,
                    ),
                    switchRow(
                      ConnectNotificationToggle.groupChats,
                      l10n.notification_row_group_chats,
                    ),
                    switchRow(
                      ConnectNotificationToggle.prayerReceived,
                      l10n.notification_row_my_prayer_requests,
                    ),
                    switchRow(
                      ConnectNotificationToggle.prayerRequest,
                      l10n.notification_row_others_prayer_requests,
                    ),
                  ],
        ),
      ],
    );
  }
}

/// Rounded, bordered group of rows with hairline dividers between them.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      // Rows ink on this card rather than on the scaffold behind it.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  color: borderColor,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color =
        enabled
            ? (isDark ? AppColors.textTertiaryDark : AppColors.textSecondary)
            : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        label,
        strutStyle: context.tibetanStrutStyle(15),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Bell, "Allow notifications", what that means right now, and the switch.
class _MasterCard extends StatelessWidget {
  const _MasterCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// What a tap on the card outside the switch does; flips it when null.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleSize = getLocalizedFontSize(AppTextSize.body);
    final subtitleSize = getLocalizedFontSize(AppTextSize.label);

    return _SettingsCard(
      children: [
        MergeSemantics(
          child: Semantics(
            toggled: value,
            child: InkWell(
              onTap: onTap ?? () => onChanged(!value),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    const Icon(AppAssets.bell, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            strutStyle: context.tibetanStrutStyle(titleSize),
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            strutStyle: context.tibetanStrutStyle(
                              subtitleSize,
                            ),
                            style: TextStyle(
                              fontSize: subtitleSize,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ExcludeSemantics(
                      child: AppToggleSwitch(
                        value: value,
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadFailedRow extends StatelessWidget {
  const _LoadFailedRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
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
