import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_item_display.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_time_utils.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_chant_list_tile.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_item_card.dart';

class RoutineTimeBlock extends StatefulWidget {
  final TimeOfDay time;
  final String? title;
  final bool notificationEnabled;
  final List<RoutineItem> items;
  final VoidCallback onTimeChanged;

  /// Fires on every keystroke with the raw text.
  final ValueChanged<String> onTitleChanged;

  /// Fires when the title field loses focus.
  final VoidCallback onTitleEditingDone;
  final VoidCallback onNotificationToggle;
  final Future<void> Function() onDelete;
  final VoidCallback onAddSession;
  final void Function(int oldIndex, int newIndex) onReorderItems;
  final void Function(int itemIndex) onDeleteItem;

  const RoutineTimeBlock({
    super.key,
    required this.time,
    this.title,
    required this.notificationEnabled,
    required this.items,
    required this.onTimeChanged,
    required this.onTitleChanged,
    required this.onTitleEditingDone,
    required this.onNotificationToggle,
    required this.onDelete,
    required this.onAddSession,
    required this.onReorderItems,
    required this.onDeleteItem,
  });

  @override
  State<RoutineTimeBlock> createState() => _RoutineTimeBlockState();
}

class _RoutineTimeBlockState extends State<RoutineTimeBlock> {
  bool _expanded = true;
  late final TextEditingController _titleController;
  final FocusNode _titleFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title ?? '');
    _titleFocus.addListener(_onTitleFocusChanged);
  }

  @override
  void didUpdateWidget(RoutineTimeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Never overwrite text the user is still typing.
    if (_titleFocus.hasFocus || widget.title == oldWidget.title) return;
    final next = widget.title ?? '';
    if (_titleController.text != next) _titleController.text = next;
  }

  @override
  void dispose() {
    _titleFocus.removeListener(_onTitleFocusChanged);
    _titleFocus.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onTitleFocusChanged() {
    if (_titleFocus.hasFocus) return;
    final trimmed = _titleController.text.trim();
    if (_titleController.text != trimmed) _titleController.text = trimmed;
    widget.onTitleEditingDone();
  }

  Future<void> _confirmDeleteItem(BuildContext context, int index) async {
    final l10n = context.l10n;
    final confirmed = await showDestructiveConfirmationDialog(
      context,
      title: l10n.removeItem,
      message: l10n.removeConfirmation(
        routineItemDisplayTitle(widget.items[index], l10n),
      ),
    );
    if (confirmed == true) {
      widget.onDeleteItem(index);
    }
  }

  Future<void> _confirmDeleteBlock(BuildContext context) async {
    final localizations = context.l10n;
    final confirmed = await showDestructiveConfirmationDialog(
      context,
      title: localizations.routine_delete_block,
      message: localizations.routine_delete_block_message,
    );
    if (confirmed == true) {
      await widget.onDelete();
    }
  }

  void _toggleExpanded() {
    if (widget.items.isEmpty) return;
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasItems = widget.items.isNotEmpty;
    final showList = _expanded && hasItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time selector row — expand control is separate so time picker
        // / notification / delete taps are not stolen.
        Row(
          children: [
            _TimeSelector(
              time: widget.time,
              onTap: widget.onTimeChanged,
              isDark: isDark,
              formattedTime: formatRoutineTime(widget.time),
            ),
            const SizedBox(width: 4),
            _NotificationIcon(
              enabled: widget.notificationEnabled,
              onTap: widget.onNotificationToggle,
              isDark: isDark,
            ),
            if (hasItems) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: _toggleExpanded,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  _expanded ? AppAssets.caretUp : AppAssets.caretDown,
                  size: 18,
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: _DeleteBlockButton(
                  onTap: () => _confirmDeleteBlock(context),
                  label: localizations.routine_delete_block,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _TitleField(
          controller: _titleController,
          focusNode: _titleFocus,
          hint: localizations.routine_session_title_hint,
          onChanged: widget.onTitleChanged,
          isDark: isDark,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child:
              showList
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: widget.items.length,
                        onReorder: widget.onReorderItems,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(12),
                            child: child,
                          );
                        },
                        itemBuilder: (context, i) {
                          final item = widget.items[i];
                          return Padding(
                            key: ValueKey(item.id),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => _confirmDeleteItem(context, i),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? AppColors.surfaceVariantDark
                                              : AppColors.grey100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        AppAssets.minus,
                                        size: 14,
                                        color:
                                            isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _buildItemTile(
                                    context,
                                    item,
                                    i,
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  )
                  : const SizedBox.shrink(),
        ),
        if (_expanded || !hasItems) ...[
          const SizedBox(height: 12),
          _AddSessionButton(
            label: localizations.routine_add_session,
            onTap: widget.onAddSession,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildItemTile(
    BuildContext context,
    RoutineItem item,
    int index,
    bool isDark,
  ) {
    final dragHandle = ReorderableDragStartListener(
      index: index,
      child: GestureDetector(
        onTapDown: (_) => HapticFeedback.heavyImpact(),
        child: Icon(
          AppAssets.list,
          size: 22,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
        ),
      ),
    );

    if (item.type == RoutineItemType.recitation) {
      return PracticeChantListTile(
        recitation: recitationModelFromRoutineItem(item),
        includeOuterPadding: false,
        showTrailingCaret: false,
        trailing: dragHandle,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.cardBackgroundDark
                : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: RoutineItemCard(
          title: routineItemDisplayTitle(item, context.l10n),
          coverImage: item.coverImage,
          type: item.type,
          reorderIndex: index,
          imageSize: 56,
        ),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;
  final bool isDark;
  final String formattedTime;

  const _TimeSelector({
    required this.time,
    required this.onTap,
    required this.isDark,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(0),
            topRight: Radius.circular(0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              AppAssets.caretDown,
              size: 18,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final bool isDark;

  const _NotificationIcon({
    required this.enabled,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => {HapticFeedback.mediumImpact(), onTap()},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Icon(
          enabled ? AppAssets.bell : AppAssets.bellSlash,
          size: 20,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _TitleField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _TitleField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      maxLength: RoutineBlock.titleMaxLength,
      buildCounter:
          (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => null,
      onChanged: onChanged,
      onSubmitted: (_) => focusNode.unfocus(),
      style: TextStyle(
        fontSize: 15,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 15,
          color:
              isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }
}

class _DeleteBlockButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _DeleteBlockButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.red.shade400,
        ),
      ),
    );
  }
}

/// Add Session button matching the design - square icon placeholder with + icon,
/// "Add Session" text, whole area clickable.
class _AddSessionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _AddSessionButton({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppAssets.plus,
                  size: 24,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
