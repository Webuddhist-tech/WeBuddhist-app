import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_add_practice_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_add_video_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_count_mode_sheet.dart';

/// Step 3 of the event composer: linked practices and About-page videos.
class GroupEventPracticesStep extends StatelessWidget {
  final GroupEventDraft draft;
  final String groupId;
  final ValueChanged<List<GroupEventPracticePick>> onPracticesChanged;
  final ValueChanged<List<GroupEventVideoDraft>> onVideosChanged;

  const GroupEventPracticesStep({
    super.key,
    required this.draft,
    required this.groupId,
    required this.onPracticesChanged,
    required this.onVideosChanged,
  });

  Future<void> _addPractice(BuildContext context) async {
    final picked = await GroupEventAddPracticeSheet.show(
      context,
      groupId: groupId,
      selected: draft.practices,
    );
    if (picked == null) return;
    onPracticesChanged(picked);
  }

  void _removePractice(GroupEventPracticePick pick) {
    onPracticesChanged(
      draft.practices.where((item) => item.id != pick.id).toList(),
    );
  }

  Future<void> _pickCountMode(
    BuildContext context,
    GroupEventPracticePick pick,
  ) async {
    final mode = await GroupEventCountModeSheet.show(
      context,
      selected: pick.countMode,
      // The event page takes attendee counts for one accumulation only.
      attendeesTaken: draft.practices.any(
        (item) =>
            item.id != pick.id &&
            item.kind == GroupEventPracticeKind.accumulator &&
            item.countMode == GroupEventCountMode.attendees,
      ),
    );
    if (mode == null) return;
    onPracticesChanged([
      for (final item in draft.practices)
        item.id == pick.id ? item.copyWith(countMode: mode) : item,
    ]);
  }

  Future<void> _addVideo(BuildContext context) async {
    final video = await GroupEventAddVideoSheet.show(context);
    if (video == null) return;
    if (draft.videos.any((item) => item.url == video.url)) return;
    onVideosChanged([...draft.videos, video]);
  }

  void _removeVideo(GroupEventVideoDraft video) {
    onVideosChanged(
      draft.videos.where((item) => item.url != video.url).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              l10n.group_event_optional_note,
              style: TextStyle(fontSize: 13, color: secondaryColor),
            ),
          ),
          _SectionLabel(l10n.group_event_practices_section, isDark: isDark),
          for (final pick in draft.practices)
            _PracticeRow(
              pick: pick,
              isDark: isDark,
              onRemove: () => _removePractice(pick),
              onCountMode:
                  pick.kind == GroupEventPracticeKind.accumulator
                      ? () => _pickCountMode(context, pick)
                      : null,
            ),
          _AddRow(
            label: l10n.group_event_add_practice,
            isDark: isDark,
            onTap: () => _addPractice(context),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _SectionLabel(l10n.group_event_videos_section, isDark: isDark),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Text(
              l10n.group_event_videos_hint,
              style: TextStyle(fontSize: 13, color: secondaryColor),
            ),
          ),
          for (final video in draft.videos)
            _VideoRow(
              video: video,
              isDark: isDark,
              onRemove: () => _removeVideo(video),
            ),
          _AddRow(
            label: l10n.group_event_add_video,
            isDark: isDark,
            onTap: () => _addVideo(context),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.accentGold : AppColors.accentGoldDarkest,
        ),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.accentGold : AppColors.accentGoldDarkest;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Icon(AppAssets.plus, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeRow extends StatelessWidget {
  const _PracticeRow({
    required this.pick,
    required this.isDark,
    required this.onRemove,
    this.onCountMode,
  });

  final GroupEventPracticePick pick;
  final bool isDark;
  final VoidCallback onRemove;
  final VoidCallback? onCountMode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PracticeThumbnail(imageUrl: pick.imageUrl, isDark: isDark),
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
              IconButton(
                onPressed: onRemove,
                tooltip: l10n.group_event_remove_practice(pick.title),
                icon: Icon(AppAssets.x, size: 18, color: secondaryColor),
              ),
            ],
          ),
          if (onCountMode != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 6, 0, 4),
              child: Row(
                children: [
                  Text(
                    l10n.group_event_counted_by,
                    style: TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Material(
                      color: Colors.transparent,
                      shape: StadiumBorder(
                        side: BorderSide(color: borderColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onCountMode,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  pick.countMode == GroupEventCountMode.admin
                                      ? l10n.group_event_count_mode_admin_short
                                      : l10n.group_event_count_mode_attendees,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                AppAssets.caretDown,
                                size: 14,
                                color: secondaryColor,
                              ),
                            ],
                          ),
                        ),
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

class _VideoRow extends StatelessWidget {
  const _VideoRow({
    required this.video,
    required this.isDark,
    required this.onRemove,
  });

  final GroupEventVideoDraft video;
  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final title = video.title?.trim();

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Icon(AppAssets.monitorPlay, size: 20, color: secondaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title == null || title.isEmpty
                      ? l10n.group_event_video_untitled
                      : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.group_event_video_source,
                  style: TextStyle(fontSize: 13, color: secondaryColor),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: l10n.group_event_remove_video,
            icon: Icon(AppAssets.x, size: 18, color: secondaryColor),
          ),
        ],
      ),
    );
  }
}
