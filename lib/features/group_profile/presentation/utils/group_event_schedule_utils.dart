import 'package:flutter_pecha/features/calendar/domain/tibetan_calendar_service.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_post_link_utils.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

/// Curated list shared with the studio; Asia/Kolkata first as the default.
class GroupEventTimezoneOption {
  final String value;
  final String label;

  const GroupEventTimezoneOption(this.value, this.label);

  static const List<GroupEventTimezoneOption> all = [
    GroupEventTimezoneOption('Asia/Kolkata', 'Asia/Kolkata (IST)'),
    GroupEventTimezoneOption('UTC', 'UTC'),
    GroupEventTimezoneOption('America/Los_Angeles', 'America/Los Angeles (PT)'),
    GroupEventTimezoneOption('America/Denver', 'America/Denver (MT)'),
    GroupEventTimezoneOption('America/Chicago', 'America/Chicago (CT)'),
    GroupEventTimezoneOption('America/New_York', 'America/New York (ET)'),
    GroupEventTimezoneOption('Europe/London', 'Europe/London (GMT/BST)'),
    GroupEventTimezoneOption('Europe/Paris', 'Europe/Paris (CET)'),
    GroupEventTimezoneOption('Asia/Dubai', 'Asia/Dubai (GST)'),
    GroupEventTimezoneOption('Asia/Kathmandu', 'Asia/Kathmandu (NPT)'),
    GroupEventTimezoneOption('Asia/Bangkok', 'Asia/Bangkok (ICT)'),
    GroupEventTimezoneOption('Asia/Shanghai', 'Asia/Shanghai (CST)'),
    GroupEventTimezoneOption('Asia/Tokyo', 'Asia/Tokyo (JST)'),
    GroupEventTimezoneOption(
      'Australia/Sydney',
      'Australia/Sydney (AEST/AEDT)',
    ),
    GroupEventTimezoneOption(
      'Pacific/Auckland',
      'Pacific/Auckland (NZST/NZDT)',
    ),
  ];

  static String labelFor(String value) =>
      all.where((option) => option.value == value).firstOrNull?.label ?? value;
}

enum GroupEventScheduleIssue {
  missingDate,
  missingRecurrence,
  endDateBeforeStart,
  endTimeBeforeStart,
}

enum GroupEventWhereIssue { missingVenue, missingLink, invalidLink }

class GroupEventScheduleUtils {
  GroupEventScheduleUtils._();

  /// Studio fallbacks when no time is chosen (all day).
  static const defaultStart = GroupEventTime(6, 0);
  static const defaultEnd = GroupEventTime(23, 59);

  /// Phugpa is what the app's calendar engine implements.
  static const lunarCalendarType = 'phugpa';

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool isPast(DateTime date) {
    final now = DateTime.now();
    return dateOnly(date).isBefore(dateOnly(now));
  }

  /// Rules a reader can pick from, all derived from the first date.
  static List<GroupEventRecurrenceDraft> rulesForDate(
    DateTime first,
    TibetanCalendarService calendar, {
    int durationDays = 1,
  }) {
    final lunar = calendar.fromWestern(first);
    return [
      GroupEventRecurrenceDraft(
        frequency: GroupEventRecurrenceFrequency.weekly,
        dateSystem: GroupEventDateSystem.gregorian,
        dayOfWeek: first.weekday - 1,
        durationDays: durationDays,
      ),
      GroupEventRecurrenceDraft(
        frequency: GroupEventRecurrenceFrequency.monthly,
        dateSystem: GroupEventDateSystem.gregorian,
        day: first.day,
        durationDays: durationDays,
      ),
      GroupEventRecurrenceDraft(
        frequency: GroupEventRecurrenceFrequency.monthly,
        dateSystem: GroupEventDateSystem.tibetanLunar,
        calendarType: lunarCalendarType,
        day: lunar.day,
        durationDays: durationDays,
      ),
      GroupEventRecurrenceDraft(
        frequency: GroupEventRecurrenceFrequency.yearly,
        dateSystem: GroupEventDateSystem.gregorian,
        month: first.month,
        day: first.day,
        durationDays: durationDays,
      ),
      GroupEventRecurrenceDraft(
        frequency: GroupEventRecurrenceFrequency.yearly,
        dateSystem: GroupEventDateSystem.tibetanLunar,
        calendarType: lunarCalendarType,
        month: lunar.month,
        day: lunar.day,
        durationDays: durationDays,
      ),
    ];
  }

  /// The next [count] occurrences strictly after [first].
  static List<DateTime> nextOccurrences(
    GroupEventRecurrenceDraft rule,
    DateTime first,
    TibetanCalendarService calendar, {
    int count = 3,
  }) {
    final start = dateOnly(first);
    if (rule.isLunar) return _nextLunar(rule, start, calendar, count);

    final results = <DateTime>[];
    switch (rule.frequency) {
      case GroupEventRecurrenceFrequency.weekly:
        for (var i = 1; i <= count; i++) {
          results.add(DateTime(start.year, start.month, start.day + 7 * i));
        }
      case GroupEventRecurrenceFrequency.monthly:
        final day = rule.day ?? start.day;
        var month = start.month;
        var year = start.year;
        while (results.length < count) {
          month += 1;
          if (month > 12) {
            month = 1;
            year += 1;
          }
          if (day <= _daysInMonth(year, month)) {
            results.add(DateTime(year, month, day));
          }
        }
      case GroupEventRecurrenceFrequency.yearly:
        final month = rule.month ?? start.month;
        final day = rule.day ?? start.day;
        var year = start.year;
        while (results.length < count) {
          year += 1;
          if (day <= _daysInMonth(year, month)) {
            results.add(DateTime(year, month, day));
          }
        }
    }
    return results;
  }

  static List<DateTime> _nextLunar(
    GroupEventRecurrenceDraft rule,
    DateTime start,
    TibetanCalendarService calendar,
    int count,
  ) {
    final results = <DateTime>[];
    final yearly = rule.frequency == GroupEventRecurrenceFrequency.yearly;
    // Lunar days repeat about every 29.5 days; scan at most a few years.
    final limit = yearly ? 400 * count : 40 * count;
    var cursor = start;
    for (var i = 0; i < limit && results.length < count; i++) {
      // Calendar days, not 24h steps, so a DST change cannot shift the date.
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
      final lunar = calendar.fromWestern(cursor);
      if (lunar.day != rule.day || lunar.isLeapDay) continue;
      if (yearly && (lunar.month != rule.month || lunar.isLeapMonth)) continue;
      results.add(cursor);
    }
    return results;
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  static GroupEventScheduleIssue? validateSchedule(
    GroupEventScheduleDraft schedule,
  ) {
    final start = schedule.startDate;
    if (start == null) return GroupEventScheduleIssue.missingDate;
    if (schedule.isRecurring) {
      if (schedule.recurrence == null) {
        return GroupEventScheduleIssue.missingRecurrence;
      }
    } else if (schedule.isMultiDay) {
      final end = schedule.endDate;
      if (end == null || dateOnly(end).isBefore(dateOnly(start))) {
        return GroupEventScheduleIssue.endDateBeforeStart;
      }
    }

    final spansDays =
        schedule.isRecurring
            ? (schedule.recurrence?.durationDays ?? 1) > 1
            : schedule.isMultiDay &&
                schedule.endDate != null &&
                !dateOnly(schedule.endDate!).isAtSameMomentAs(dateOnly(start));
    if (!schedule.allDay && !spansDays) {
      final from = schedule.startTime ?? defaultStart;
      final to = schedule.endTime ?? defaultEnd;
      if (to.minutesSinceMidnight <= from.minutesSinceMidnight) {
        return GroupEventScheduleIssue.endTimeBeforeStart;
      }
    }
    return null;
  }

  static GroupEventWhereIssue? validateWhere(GroupEventDraft draft) {
    if (draft.format.needsVenue && draft.venue == null) {
      return GroupEventWhereIssue.missingVenue;
    }
    if (draft.format.needsLink) {
      final raw = draft.liveLink.trim();
      if (raw.isEmpty) return GroupEventWhereIssue.missingLink;
      if (normalizeLiveLink(raw) == null) {
        return GroupEventWhereIssue.invalidLink;
      }
    }
    return null;
  }

  /// An `https://` URL for what was typed, or null when it isn't one.
  static String? normalizeLiveLink(String input) =>
      ConnectPostLinkUtils.normalizeUserUrl(input);

  static bool isYoutubeLink(String url) {
    final host = ConnectPostLinkUtils.hostOf(url);
    return host != null &&
        (host == 'youtube.com' ||
            host.endsWith('.youtube.com') ||
            host == 'youtu.be');
  }

  /// The group's YouTube channel as a `/live` URL, if it links a channel.
  static String? channelLiveUrl(List<GroupProfileSocialLink> links) {
    for (final link in links) {
      if (link.platform.trim().toLowerCase() != 'youtube') continue;
      final normalized = normalizeLiveLink(link.url);
      if (normalized == null) continue;
      final uri = Uri.parse(normalized);
      final host = ConnectPostLinkUtils.hostOf(normalized) ?? '';
      if (host != 'youtube.com' && !host.endsWith('.youtube.com')) continue;
      final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
      if (parts.isEmpty) continue;
      final first = parts.first;
      const notChannels = {
        'watch',
        'playlist',
        'shorts',
        'live',
        'embed',
        'results',
      };
      if (notChannels.contains(first)) continue;
      final channelPath =
          first.startsWith('@') || parts.length == 1
              ? [first]
              : (const {'channel', 'user', 'c'}.contains(first)
                  ? parts.take(2).toList()
                  : [first]);
      return 'https://www.youtube.com/${channelPath.join('/')}/live';
    }
    return null;
  }
}
