import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_event_composer_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chat, notifications and prayer intentions; the studio's Settings tab.
class GroupEventSettingsSheet extends ConsumerStatefulWidget {
  final GroupEventDraft draft;

  const GroupEventSettingsSheet({super.key, required this.draft});

  /// Pops with the updated draft, or null when dismissed.
  static Future<GroupEventDraft?> show(
    BuildContext context, {
    required GroupEventDraft draft,
  }) {
    return GroupEventSheet.show<GroupEventDraft>(
      context,
      builder: (_) => GroupEventSettingsSheet(draft: draft),
    );
  }

  @override
  ConsumerState<GroupEventSettingsSheet> createState() =>
      _GroupEventSettingsSheetState();
}

class _GroupEventSettingsSheetState
    extends ConsumerState<GroupEventSettingsSheet> {
  late bool _chat = widget.draft.chatEnabled;
  late bool _notifications = widget.draft.notificationsEnabled;
  late Set<String> _intentions = {...widget.draft.intentionIds};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final intentionsAsync = ref.watch(groupEventIntentionsProvider);

    return GroupEventSheet(
      title: l10n.group_event_settings_title,
      maxHeightFactor: 0.9,
      footer: GroupEventSheet.primaryButton(
        context,
        label: l10n.done,
        onPressed:
            () => Navigator.of(context).pop(
              widget.draft.copyWith(
                chatEnabled: _chat,
                notificationsEnabled: _notifications,
                intentionIds: _intentions.toList(),
              ),
            ),
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          _ToggleRow(
            label: l10n.group_event_settings_chat,
            hint: l10n.group_event_settings_chat_hint,
            value: _chat,
            onChanged: (value) => setState(() => _chat = value),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _ToggleRow(
            label: l10n.group_event_settings_notifications,
            hint: l10n.group_event_settings_notifications_hint,
            value: _notifications,
            onChanged: (value) => setState(() => _notifications = value),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.group_event_settings_intentions.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color:
                        isDark
                            ? AppColors.accentGold
                            : AppColors.accentGoldDarkest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.group_event_settings_intentions_hint,
                  style: TextStyle(fontSize: 12, color: secondaryColor),
                ),
              ],
            ),
          ),
          intentionsAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            error:
                (_, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Text(
                    l10n.group_event_settings_intentions_error,
                    style: TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                ),
            data:
                (intentions) => Column(
                  children: [
                    for (final intention in intentions) ...[
                      InkWell(
                        onTap: () => _toggle(intention.id),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 2, 16, 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  intention.label,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              Checkbox(
                                value: _intentions.contains(intention.id),
                                onChanged: (_) => _toggle(intention.id),
                                activeColor:
                                    isDark
                                        ? AppColors.surfaceWhite
                                        : AppColors.textPrimary,
                                checkColor:
                                    isDark
                                        ? AppColors.textPrimary
                                        : AppColors.surfaceWhite,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: dividerColor),
                    ],
                  ],
                ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _toggle(String id) {
    setState(() {
      _intentions =
          _intentions.contains(id)
              ? (_intentions..remove(id))
              : (_intentions..add(id));
    });
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 16)),
              ),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              hint,
              style: TextStyle(fontSize: 12, color: secondaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
