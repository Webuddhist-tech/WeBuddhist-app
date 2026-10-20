import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_event_composer_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Filter { all, content, collections, accumulators }

/// Turns a practices-feed item into a pick; null for items with no id.
GroupEventPracticePick? practicePickFrom(GroupPractice practice) {
  switch (practice.type) {
    case GroupPracticeType.plan:
      final plan = practice.plan;
      if (plan == null || plan.id.isEmpty) return null;
      return GroupEventPracticePick(
        id: plan.id,
        kind: GroupEventPracticeKind.plan,
        title: plan.title,
        imageUrl: plan.imageUrl,
      );
    case GroupPracticeType.series:
      final series = practice.series;
      if (series == null || series.id.isEmpty) return null;
      return GroupEventPracticePick(
        id: series.id,
        kind: GroupEventPracticeKind.series,
        title: series.title,
        imageUrl: series.image?.displayUrl,
      );
    case GroupPracticeType.collection:
      final collection = practice.collection;
      if (collection == null || collection.id.isEmpty) return null;
      return GroupEventPracticePick(
        id: collection.id,
        kind: GroupEventPracticeKind.collection,
        title: collection.name,
        imageUrl: collection.imageUrl,
      );
    case GroupPracticeType.accumulator:
      final accumulator = practice.accumulator;
      if (accumulator == null || accumulator.id.isEmpty) return null;
      return GroupEventPracticePick(
        id: accumulator.id,
        kind: GroupEventPracticeKind.accumulator,
        title: accumulator.title,
        imageUrl: accumulator.image?.displayUrl,
      );
  }
}

/// Adds [pick] to [current], replacing the single-slot kinds. Returns the new
/// list and what was replaced, if anything.
(List<GroupEventPracticePick>, GroupEventPracticePick?) addPracticePick(
  List<GroupEventPracticePick> current,
  GroupEventPracticePick pick,
) {
  GroupEventPracticePick? replaced;
  final next = <GroupEventPracticePick>[];
  for (final existing in current) {
    final clashes =
        pick.isContent && existing.isContent ||
        pick.kind == GroupEventPracticeKind.collection &&
            existing.kind == GroupEventPracticeKind.collection;
    if (clashes && existing.id != pick.id) {
      replaced = existing;
      continue;
    }
    if (existing.id == pick.id) continue;
    next.add(existing);
  }
  next.add(pick);
  return (next, replaced);
}

/// Multi-select over the group's practices; pops with the new full selection.
class GroupEventAddPracticeSheet extends ConsumerStatefulWidget {
  final String groupId;
  final List<GroupEventPracticePick> selected;

  const GroupEventAddPracticeSheet({
    super.key,
    required this.groupId,
    required this.selected,
  });

  static Future<List<GroupEventPracticePick>?> show(
    BuildContext context, {
    required String groupId,
    required List<GroupEventPracticePick> selected,
  }) {
    return GroupEventSheet.show<List<GroupEventPracticePick>>(
      context,
      builder:
          (_) =>
              GroupEventAddPracticeSheet(groupId: groupId, selected: selected),
    );
  }

  @override
  ConsumerState<GroupEventAddPracticeSheet> createState() =>
      _GroupEventAddPracticeSheetState();
}

class _GroupEventAddPracticeSheetState
    extends ConsumerState<GroupEventAddPracticeSheet> {
  final TextEditingController _query = TextEditingController();
  late List<GroupEventPracticePick> _selected = [...widget.selected];
  _Filter _filter = _Filter.all;
  (String chosen, String previous)? _replacement;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _isSelected(GroupEventPracticePick pick) =>
      _selected.any((item) => item.id == pick.id);

  void _toggle(GroupEventPracticePick pick) {
    setState(() {
      if (_isSelected(pick)) {
        _selected = _selected.where((item) => item.id != pick.id).toList();
        _replacement = null;
        return;
      }
      final (next, replaced) = addPracticePick(_selected, pick);
      _selected = next;
      _replacement = replaced == null ? null : (pick.title, replaced.title);
    });
  }

  bool _matchesFilter(GroupEventPracticePick pick) => switch (_filter) {
    _Filter.all => true,
    _Filter.content => pick.isContent,
    _Filter.collections => pick.kind == GroupEventPracticeKind.collection,
    _Filter.accumulators => pick.kind == GroupEventPracticeKind.accumulator,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final optionsAsync = ref.watch(
      groupEventPracticeOptionsProvider(widget.groupId),
    );
    final needle = _query.text.trim().toLowerCase();
    final replacement = _replacement;

    return GroupEventSheet(
      title: l10n.group_event_add_practice,
      maxHeightFactor: 0.9,
      footer: GroupEventSheet.primaryButton(
        context,
        label: l10n.group_event_add_practices_count(_selected.length),
        onPressed: () => Navigator.of(context).pop(_selected),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: TextField(
              controller: _query,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: l10n.group_event_practice_search_hint,
                hintStyle: TextStyle(fontSize: 15, color: secondaryColor),
                prefixIcon: Icon(
                  AppAssets.exploreUnselected,
                  size: 18,
                  color: secondaryColor,
                ),
                filled: true,
                fillColor:
                    isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceWhite,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final filter in _Filter.values) ...[
                  _FilterChip(
                    label: switch (filter) {
                      _Filter.all => l10n.group_event_practice_filter_all,
                      _Filter.content =>
                        l10n.group_event_practice_filter_content,
                      _Filter.collections =>
                        l10n.group_event_practice_filter_collections,
                      _Filter.accumulators =>
                        l10n.group_event_practice_filter_accumulators,
                    },
                    selected: filter == _filter,
                    isDark: isDark,
                    onTap: () => setState(() => _filter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Text(
              replacement == null
                  ? l10n.group_event_practice_rule
                  : l10n.group_event_practice_replaced(
                    replacement.$1,
                    replacement.$2,
                  ),
              style: TextStyle(fontSize: 12, color: secondaryColor),
            ),
          ),
          Flexible(
            child: optionsAsync.when(
              loading:
                  () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (error, _) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: ErrorStateWidget(
                      error: error,
                      customMessage: l10n.group_event_practices_load_error,
                      onRetry:
                          () => ref.invalidate(
                            groupEventPracticeOptionsProvider(widget.groupId),
                          ),
                    ),
                  ),
              data: (practices) {
                final seen = <String>{};
                final picks = [
                  for (final practice in practices)
                    if (practicePickFrom(practice) case final pick?)
                      if (seen.add(pick.id) &&
                          _matchesFilter(pick) &&
                          (needle.isEmpty ||
                              pick.title.toLowerCase().contains(needle)))
                        pick,
                ];
                if (picks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Text(
                      practices.isEmpty
                          ? l10n.group_event_practices_empty
                          : l10n.group_event_practices_none_match,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: secondaryColor),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: picks.length,
                  separatorBuilder:
                      (_, _) =>
                          Divider(height: 1, thickness: 1, color: dividerColor),
                  itemBuilder: (context, index) {
                    final pick = picks[index];
                    final checked = _isSelected(pick);
                    return InkWell(
                      onTap: () => _toggle(pick),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                        child: Row(
                          children: [
                            PracticeThumbnail(
                              imageUrl: pick.imageUrl,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pick.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Checkbox(
                              value: checked,
                              onChanged: (_) => _toggle(pick),
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeBackground =
        isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final activeForeground =
        isDark ? AppColors.textPrimary : AppColors.surfaceWhite;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    return Material(
      color: selected ? activeBackground : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? activeBackground : borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  selected
                      ? activeForeground
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square thumbnail used by the picker and the step's practice rows.
class PracticeThumbnail extends StatelessWidget {
  const PracticeThumbnail({
    super.key,
    required this.imageUrl,
    required this.isDark,
  });

  final String? imageUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.image,
        size: 20,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child:
            imageUrl == null || imageUrl!.isEmpty
                ? fallback
                : CachedNetworkImageWidget(
                  imageUrl: imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorWidget: fallback,
                ),
      ),
    );
  }
}
