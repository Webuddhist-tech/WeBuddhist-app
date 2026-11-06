import 'package:flutter_pecha/features/calendar/domain/models/moon_phase.dart';
import 'package:flutter_pecha/features/calendar/domain/models/personal_calendar_event.dart';

/// Where a [CalendarEvent] came from. Also the order within one day.
enum CalendarEventKind {
  /// Computed offline from the lunar day (new/quarter/full moons).
  lunarPhase,

  /// From a space the viewer has joined.
  group,
}

/// A single dated entry shown in the calendar's events list and as a grid
/// marker. [title] is already localized/display-ready.
class CalendarEvent {
  /// Gregorian date (date-only, midnight local) the event falls on.
  final DateTime date;

  /// Tibetan lunar day (1–30) of [date], when known.
  final int? lunarDay;

  /// Display title, e.g. "Full moon" or "Saga Dawa".
  final String title;

  final CalendarEventKind kind;

  /// Set for [CalendarEventKind.lunarPhase] events; null otherwise.
  final MoonPhase? phase;

  /// The space event this entry opens. Null for lunar events.
  final String? eventId;

  /// The space the card credits. Null for lunar events.
  final String? sourceName;
  final String? sourceAvatarUrl;

  final bool allDay;

  /// When this date's session starts; null when all day.
  final DateTime? startsAt;

  /// The whole span of a space event that runs over several days.
  final DateTime? startDate;
  final DateTime? endDate;

  final PersonalRepeat? repeat;
  final int? repeatDay;

  const CalendarEvent({
    required this.date,
    this.lunarDay,
    required this.title,
    required this.kind,
    this.phase,
    this.eventId,
    this.sourceName,
    this.sourceAvatarUrl,
    this.allDay = true,
    this.startsAt,
    this.startDate,
    this.endDate,
    this.repeat,
    this.repeatDay,
  });

  /// Lunar events have nowhere to open.
  bool get isTappable => eventId != null;

  bool get isRepeating => repeat != null && repeat != PersonalRepeat.none;

  @override
  String toString() => 'CalendarEvent($date, day $lunarDay, $title, $kind)';
}

/// One page of the calendar feed.
class CalendarFeedPage {
  final List<CalendarEvent> events;

  /// Rows read from the server, including any the app doesn't show.
  final int rowCount;
  final bool hasMore;

  const CalendarFeedPage({
    required this.events,
    required this.rowCount,
    required this.hasMore,
  });
}
