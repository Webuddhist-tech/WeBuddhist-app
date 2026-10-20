import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_post_link_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_schedule_utils.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_repeats_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_when_where_step.dart';
import 'package:intl/intl.dart';

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
  static String eventName(GroupEventDraft draft) {
    final named = draft.metadata.where((m) => m.hasName).firstOrNull;
    return named?.name.trim() ?? '';
  }

  String _languageNames() {
    return draft.metadata
        .where((m) => m.hasName)
        .map(
          (m) =>
              languages
                  .where((language) => language.code == m.language)
                  .firstOrNull
                  ?.nativeName ??
              m.language,
        )
        .join(', ');
  }

  String _when(AppLocalizations l10n, String locale) {
    final schedule = draft.schedule;
    final start = schedule.startDate;
    if (start == null) return l10n.group_event_choose_date;
    final times =
        schedule.allDay
            ? l10n.group_event_all_day
            : '${GroupEventWhenWhereStep.formatTime(schedule.startTime ?? GroupEventScheduleUtils.defaultStart, locale)} – ${GroupEventWhenWhereStep.formatTime(schedule.endTime ?? GroupEventScheduleUtils.defaultEnd, locale)}';
    final rule = schedule.recurrence;
    if (schedule.isRecurring && rule != null) {
      return l10n.group_event_review_recurring_from(
        recurrenceRuleLabel(rule, start, l10n, locale),
        times,
        DateFormat('d MMM yyyy', locale).format(start),
      );
    }
    final end = schedule.effectiveEndDate;
    final dates =
        end != null &&
                !GroupEventScheduleUtils.dateOnly(
                  end,
                ).isAtSameMomentAs(GroupEventScheduleUtils.dateOnly(start))
            ? '${DateFormat('d MMM', locale).format(start)} – ${DateFormat('d MMM yyyy', locale).format(end)}'
            : GroupEventWhenWhereStep.formatDate(start, locale);
    return '$dates · $times';
  }

  String _where(AppLocalizations l10n) {
    final venue = draft.venue?.name;
    return switch (draft.format) {
      GroupEventFormat.offline =>
        venue == null
            ? l10n.group_event_in_person
            : '${l10n.group_event_in_person} · $venue',
      GroupEventFormat.online => l10n.group_event_review_online,
      GroupEventFormat.hybrid =>
        venue == null
            ? l10n.group_event_both
            : '${l10n.group_event_both} · $venue',
    };
  }

  String _liveLink(AppLocalizations l10n) {
    final url = GroupEventScheduleUtils.normalizeLiveLink(draft.liveLink);
    if (url == null) return l10n.group_event_review_none;
    if (GroupEventScheduleUtils.isYoutubeLink(url)) {
      final handle =
          Uri.parse(
            url,
          ).pathSegments.where((p) => p.startsWith('@')).firstOrNull;
      return handle == null
          ? l10n.group_event_review_youtube_live
          : '${l10n.group_event_review_youtube_live} · $handle';
    }
    return ConnectPostLinkUtils.shortUrl(url);
  }

  String _list(AppLocalizations l10n, List<String> titles) {
    if (titles.isEmpty) return l10n.group_event_review_none;
    if (titles.length == 1) return titles.first;
    return l10n.group_event_review_more(titles.first, titles.length - 1);
  }

  String _settings(AppLocalizations l10n) {
    final intentions =
        draft.intentionIds.isEmpty
            ? l10n.group_event_all_intentions
            : l10n.group_event_intentions_count(draft.intentionIds.length);
    return [
      draft.chatEnabled ? l10n.group_event_chat_on : l10n.group_event_chat_off,
      draft.notificationsEnabled
          ? l10n.group_event_notifications_on
          : l10n.group_event_notifications_off,
      intentions,
    ].join(' · ');
  }

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
          _SectionLabel(l10n.group_event_review_event, isDark: isDark),
          _ReviewRow(
            icon: AppAssets.list,
            label: l10n.group_event_review_name,
            value: name.isEmpty ? l10n.group_event_review_none : name,
            onTap: () => onEdit(GroupEventReviewTarget.about),
          ),
          _ReviewRow(
            icon: AppAssets.translate,
            label: l10n.group_event_review_languages,
            value: _languageNames(),
            onTap: () => onEdit(GroupEventReviewTarget.about),
          ),
          _ReviewRow(
            icon: AppAssets.calendarBlank,
            label: l10n.group_event_review_when,
            value: _when(l10n, locale),
            onTap: () => onEdit(GroupEventReviewTarget.whenWhere),
          ),
          _ReviewRow(
            icon: AppAssets.mapPin,
            label: l10n.group_event_review_where,
            value: _where(l10n),
            onTap: () => onEdit(GroupEventReviewTarget.whenWhere),
          ),
          if (draft.format.needsLink)
            _ReviewRow(
              icon: AppAssets.monitorPlay,
              label: l10n.group_event_review_live_link,
              value: _liveLink(l10n),
              onTap: () => onEdit(GroupEventReviewTarget.whenWhere),
            ),
          _SectionLabel(l10n.group_event_step_practices, isDark: isDark),
          _ReviewRow(
            icon: AppAssets.list,
            label: l10n.group_event_review_practices,
            value: _list(l10n, [for (final p in draft.practices) p.title]),
            onTap: () => onEdit(GroupEventReviewTarget.practices),
          ),
          _ReviewRow(
            icon: AppAssets.monitorPlay,
            label: l10n.group_event_review_videos,
            value: _list(l10n, [
              for (final v in draft.videos)
                v.title?.trim().isNotEmpty == true
                    ? v.title!.trim()
                    : l10n.group_event_video_untitled,
            ]),
            onTap: () => onEdit(GroupEventReviewTarget.practices),
          ),
          _SectionLabel(l10n.group_event_review_settings, isDark: isDark),
          _ReviewRow(
            icon: AppAssets.sliders,
            label: l10n.group_event_review_event_settings,
            value: _settings(l10n),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.isDark});

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

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
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
