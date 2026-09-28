import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_member.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ban lengths offered to an admin. Values stay inside the API range of 1–365.
const List<int> groupRemoveBanDurations = [1, 7, 30, 90, 365];

class GroupRemoveMemberSheet extends ConsumerStatefulWidget {
  final String groupId;
  final GroupMember member;

  const GroupRemoveMemberSheet({
    super.key,
    required this.groupId,
    required this.member,
  });

  static const int maxReasonLength = 200;
  static const int defaultBanDays = 7;

  static Future<bool?> show(
    BuildContext context, {
    required String groupId,
    required GroupMember member,
  }) {
    // Drag-to-close pops the route directly and skips [PopScope], so a drag
    // mid-request would close the sheet while the removal still completes and
    // the caller would never learn the outcome. Barrier taps and the close
    // button go through `maybePop` and honour the submit lock.
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => GroupRemoveMemberSheet(groupId: groupId, member: member),
    );
  }

  @override
  ConsumerState<GroupRemoveMemberSheet> createState() =>
      _GroupRemoveMemberSheetState();
}

class _GroupRemoveMemberSheetState
    extends ConsumerState<GroupRemoveMemberSheet> {
  final TextEditingController _reasonController = TextEditingController();
  int _banDays = GroupRemoveMemberSheet.defaultBanDays;
  bool _durationOpen = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _displayName(GroupMember member) {
    final fullname = member.fullname.trim();
    if (fullname.isNotEmpty) return fullname;
    return member.username;
  }

  String _durationLabel(BuildContext context, int days) {
    final l10n = context.l10n;
    if (days == 1) return l10n.group_remove_member_duration_day;
    if (days == 365) return l10n.group_remove_member_duration_year;
    return l10n.group_remove_member_duration_days(days);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final userId = widget.member.userId.trim();
    if (userId.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _durationOpen = false;
    });

    final reason = _reasonController.text.trim();
    final removed = await ref
        .read(groupMembersProvider(widget.groupId).notifier)
        .removeMember(
          userId: userId,
          banDurationDays: _banDays,
          reason: reason.isEmpty ? null : reason,
        );

    if (!mounted) return;
    if (removed) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.group_remove_member_error),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final name = _displayName(widget.member);

    return PopScope(
      canPop: !_isSubmitting,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.group_remove_member_title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed:
                              _isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: l10n.close,
                        ),
                      ],
                    ),
                    Text(
                      l10n.group_remove_member_message(name),
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.group_remove_member_blocked_for,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DurationField(
                      label: _durationLabel(context, _banDays),
                      isOpen: _durationOpen,
                      enabled: !_isSubmitting,
                      isDark: isDark,
                      onTap:
                          () => setState(() => _durationOpen = !_durationOpen),
                    ),
                    if (_durationOpen) ...[
                      const SizedBox(height: 4),
                      _DurationMenu(
                        isDark: isDark,
                        selectedDays: _banDays,
                        labelFor: (days) => _durationLabel(context, days),
                        onSelected: (days) {
                          setState(() {
                            _banDays = days;
                            _durationOpen = false;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      l10n.group_remove_member_reason_label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      enabled: !_isSubmitting,
                      maxLength: GroupRemoveMemberSheet.maxReasonLength,
                      minLines: 4,
                      maxLines: 4,
                      onTap: () {
                        if (_durationOpen) {
                          setState(() => _durationOpen = false);
                        }
                      },
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: l10n.group_remove_member_reason_hint,
                        counterText:
                            '${_reasonController.text.characters.length}/${GroupRemoveMemberSheet.maxReasonLength}',
                        filled: true,
                        fillColor:
                            isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.surfaceWhite,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDark
                                    ? AppColors.cardBorderDark
                                    : AppColors.grey300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDark ? AppColors.grey500 : AppColors.grey800,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark
                                  ? AppColors.surfaceWhite
                                  : AppColors.textPrimary,
                          foregroundColor:
                              isDark
                                  ? AppColors.textPrimary
                                  : AppColors.surfaceWhite,
                          disabledBackgroundColor:
                              isDark
                                  ? AppColors.surfaceWhite
                                  : AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isSubmitting
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        isDark
                                            ? AppColors.textPrimary
                                            : AppColors.surfaceWhite,
                                  ),
                                )
                                : Text(
                                  l10n.group_remove_member_action,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationField extends StatelessWidget {
  final String label;
  final bool isOpen;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  const _DurationField({
    required this.label,
    required this.isOpen,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 16)),
              ),
              Icon(
                isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationMenu extends StatelessWidget {
  final bool isDark;
  final int selectedDays;
  final String Function(int days) labelFor;
  final ValueChanged<int> onSelected;

  const _DurationMenu({
    required this.isDark,
    required this.selectedDays,
    required this.labelFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.surfaceWhite,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
        ),
      ),
      child: Column(
        children: [
          for (final days in groupRemoveBanDurations)
            InkWell(
              onTap: () => onSelected(days),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        labelFor(days),
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              days == selectedDays
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary),
                          fontWeight:
                              days == selectedDays
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (days == selectedDays)
                      const Icon(
                        Icons.check,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
