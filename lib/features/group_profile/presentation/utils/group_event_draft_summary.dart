import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_post_link_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_schedule_utils.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_repeats_sheet.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_when_where_step.dart';
import 'package:intl/intl.dart';

/// One-line read-backs of a draft, shared by the review step and the
/// manage screen.
abstract final class GroupEventDraftSummary {
  static String eventName(GroupEventDraft draft) {
    final named = draft.metadata.where((m) => m.hasName).firstOrNull;
    return named?.name.trim() ?? '';
  }

  static String languageNames(
    GroupEventDraft draft,
    List<AppLanguage> languages,
  ) {
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

  static String when(
    GroupEventDraft draft,
    AppLocalizations l10n,
    String locale,
  ) {
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

  static String where(GroupEventDraft draft, AppLocalizations l10n) {
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

  static String liveLink(GroupEventDraft draft, AppLocalizations l10n) {
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

  static String practices(GroupEventDraft draft, AppLocalizations l10n) =>
      list(l10n, [for (final p in draft.practices) p.title]);

  static String videos(GroupEventDraft draft, AppLocalizations l10n) =>
      list(l10n, [
        for (final v in draft.videos)
          v.title?.trim().isNotEmpty == true
              ? v.title!.trim()
              : l10n.group_event_video_untitled,
      ]);

  static String settings(GroupEventDraft draft, AppLocalizations l10n) {
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

  static String list(AppLocalizations l10n, List<String> titles) {
    if (titles.isEmpty) return l10n.group_event_review_none;
    if (titles.length == 1) return titles.first;
    return l10n.group_event_review_more(titles.first, titles.length - 1);
  }
}
