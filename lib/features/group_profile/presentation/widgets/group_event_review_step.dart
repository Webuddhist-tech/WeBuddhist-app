import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_draft_summary.dart';

/// Which earlier step a review row jumps back to.
enum GroupEventReviewTarget { about, whenWhere, practices, settings }

/// Step 4 of the event composer: a read-back of every step before publishing.
class GroupEventReviewStep extends StatelessWidget {
  final GroupEventDraft draft;
  final List<AppLanguage> languages;
  final ValueChanged<GroupEventReviewTarget> onEdit;

  const GroupEventReviewStep({
    super.key,
    required this.draft,
    required this.languages,
    required this.onEdit,
  });

  /// Shared with the published view.
  static String eventName(GroupEventDraft draft) =>
      GroupEventDraftSummary.eventName(draft);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = intlFormatLocaleOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final name = eventName(draft);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (draft.cover != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: GroupEventCoverImage(cover: draft.cover!, isDark: isDark),
            ),
          GroupEventSectionLabel(l10n.group_event_review_event, isDark: isDark),
          GroupEventReviewRow(
            icon: AppAssets.list,
            label: l10n.group_event_review_name,
            value: name.isEmpty ? l10n.group_event_review_none : name,
            onTap: () => onEdit(GroupEventReviewTarget.about),
          ),
          GroupEventReviewRow(
            icon: AppAssets.translate,
            label: l10n.group_event_review_languages,
            value: GroupEventDraftSummary.languageNames(draft, languages),
            onTap: () => onEdit(GroupEventReviewTarget.about),
          ),
          GroupEventReviewRow(
            icon: AppAssets.calendarBlank,
            label: l10n.group_event_review_when,
            value: GroupEventDraftSummary.when(draft, l10n, locale),
            onTap: () => onEdit(GroupEventReviewTarget.whenWhere),
          ),
          GroupEventReviewRow(
            icon: AppAssets.mapPin,
            label: l10n.group_event_review_where,
            value: GroupEventDraftSummary.where(draft, l10n),
            onTap: () => onEdit(GroupEventReviewTarget.whenWhere),
          ),
          if (draft.format.needsLink)
            GroupEventReviewRow(
              icon: AppAssets.monitorPlay,
              label: l10n.group_event_review_live_link,
              value: GroupEventDraftSummary.liveLink(draft, l10n),
              onTap: () => onEdit(GroupEventReviewTarget.whenWhere),
            ),
          GroupEventSectionLabel(l10n.group_event_step_practices, isDark: isDark),
          GroupEventReviewRow(
            icon: AppAssets.list,
            label: l10n.group_event_review_practices,
            value: GroupEventDraftSummary.practices(draft, l10n),
            onTap: () => onEdit(GroupEventReviewTarget.practices),
          ),
          GroupEventReviewRow(
            icon: AppAssets.monitorPlay,
            label: l10n.group_event_review_videos,
            value: GroupEventDraftSummary.videos(draft, l10n),
            onTap: () => onEdit(GroupEventReviewTarget.practices),
          ),
          GroupEventSectionLabel(l10n.group_event_review_settings, isDark: isDark),
          GroupEventReviewRow(
            icon: AppAssets.sliders,
            label: l10n.group_event_review_event_settings,
            value: GroupEventDraftSummary.settings(draft, l10n),
            onTap: () => onEdit(GroupEventReviewTarget.settings),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              l10n.group_event_review_tap_hint,
              style: TextStyle(fontSize: 12, color: secondaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cover as picked in step 1, used by the review and published views.
class GroupEventCoverImage extends StatelessWidget {
  const GroupEventCoverImage({
    super.key,
    required this.cover,
    required this.isDark,
  });

  final GroupEventCover cover;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 8,
        child: switch (cover) {
          GroupEventCoverFile(:final file) => Image.file(
            file,
            fit: BoxFit.cover,
          ),
          GroupEventCoverUrl(:final url) => CachedNetworkImageWidget(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: ColoredBox(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            ),
          ),
        },
      ),
    );
  }
}

/// Gold uppercase heading over a group of rows.
class GroupEventSectionLabel extends StatelessWidget {
  const GroupEventSectionLabel(this.text, {super.key, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
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

/// Icon, label over value, chevron: one editable fact about the event.
class GroupEventReviewRow extends StatelessWidget {
  const GroupEventReviewRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: dividerColor)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: secondaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: secondaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Icon(AppAssets.caretRight, size: 18, color: secondaryColor),
          ],
        ),
      ),
    );
  }
}
