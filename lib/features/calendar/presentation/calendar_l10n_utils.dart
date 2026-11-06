import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/models/moon_phase.dart';
import 'package:flutter_pecha/features/calendar/domain/models/personal_calendar_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_time_format.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_event_repeats_sheet.dart';

/// A locale name safe to pass to `intl`'s [DateFormat] (and `table_calendar`).
String dateFormatLocale(BuildContext context) => intlFormatLocaleOf(context);

/// Localized display name for a [MoonPhase].
String moonPhaseLabel(AppLocalizations l10n, MoonPhase phase) {
  switch (phase) {
    case MoonPhase.newMoon:
      return l10n.moon_phase_new_moon;
    case MoonPhase.firstQuarter:
      return l10n.moon_phase_first_quarter;
    case MoonPhase.fullMoon:
      return l10n.moon_phase_full_moon;
    default:
      return "";
  }
}

/// Whether a moon phase should be surfaced in the UI (home card, events list).
bool showsMoonPhaseLabel(MoonPhase phase) {
  return switch (phase) {
    MoonPhase.newMoon || MoonPhase.firstQuarter || MoonPhase.fullMoon => true,
    _ => false,
  };
}

/// Whether an event should appear in the upcoming-events list.
bool showsInUpcomingEvents(CalendarEvent event) {
  if (event.kind != CalendarEventKind.lunarPhase) return true;
  final phase = event.phase;
  return phase != null && showsMoonPhaseLabel(phase);
}

/// Display title for an event: a localized phase name for computed lunar-phase
/// events, otherwise the event's own title.
String eventTitle(AppLocalizations l10n, CalendarEvent event) {
  final phase = event.phase;
  if (event.kind == CalendarEventKind.lunarPhase && phase != null) {
    return moonPhaseLabel(l10n, phase);
  }
  return event.title;
}

/// Short repeat label for a card, e.g. "Monthly (15th lunar)". Null when the
/// event doesn't repeat.
String? calendarRepeatLabel(
  AppLocalizations l10n,
  PersonalRepeat? repeat,
  int? day,
  String locale,
) {
  return switch (repeat) {
    null || PersonalRepeat.none => null,
    PersonalRepeat.weekly => l10n.calendar_repeat_weekly,
    PersonalRepeat.monthlyGregorian => l10n.calendar_repeat_monthly,
    PersonalRepeat.monthlyLunar =>
      day != null
          ? l10n.calendar_repeat_monthly_lunar(ordinalDay(day, locale))
          : l10n.calendar_repeat_monthly,
    PersonalRepeat.yearlyGregorian => l10n.calendar_repeat_yearly,
    PersonalRepeat.yearlyLunar => l10n.calendar_repeat_yearly_lunar,
  };
}

/// The line under a card's title: when the event happens and how it repeats.
String eventDetailLine(BuildContext context, CalendarEvent event) {
  final l10n = AppLocalizations.of(context)!;
  final locale = dateFormatLocale(context);
  final repeat = calendarRepeatLabel(
    l10n,
    event.repeat,
    event.repeatDay,
    locale,
  );
  final startsAt = event.startsAt;
  final when =
      event.allDay || startsAt == null
          ? l10n.group_event_all_day
          : formatGroupEventTime(startsAt, locale);
  if (repeat != null) return '$repeat · $when';

  final start = event.startDate;
  final end = event.endDate;
  if (start != null && end != null && !DateUtils.isSameDay(start, end)) {
    return formatGroupEventDayRange(start, end, locale, separator: ' – ');
  }
  return when;
}

/// "{ordinal} lunar month" — e.g. "4th lunar month" in English. For non-English
/// locales the bare month number is interpolated (the arb template positions it
/// appropriately, e.g. "藏历4月").
String lunarMonthLabel(BuildContext context, AppLocalizations l10n, int month) {
  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
  final ordinal = isEnglish ? _englishOrdinal(month) : '$month';
  return l10n.calendar_lunar_month(ordinal);
}

String _englishOrdinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}
