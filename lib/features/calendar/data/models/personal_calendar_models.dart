import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/models/personal_calendar_event.dart';

/// `yyyy-MM-dd`, as the API takes dates.
String formatApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// `GET /users/me/calendar` rows. Lunar days are left out: the app works those
/// out itself so guests and offline users still see them.
CalendarFeedPage calendarFeedPageFromJson(Map<String, dynamic> json) {
  final rows =
      (json['items'] as List? ?? const []).cast<Map<String, dynamic>>();
  return CalendarFeedPage(
    events: rows.map(_eventFromJson).nonNulls.toList(),
    rowCount: rows.length,
    hasMore: json['has_more'] as bool? ?? false,
  );
}

CalendarEvent? _eventFromJson(Map<String, dynamic> json) {
  final kind = switch (json['kind']) {
    'PERSONAL' => CalendarEventKind.personal,
    'GROUP_EVENT' => CalendarEventKind.group,
    _ => null,
  };
  final id = json['id'] as String?;
  if (kind == null || id == null) return null;
  final source = json['source'] as Map<String, dynamic>?;
  return CalendarEvent(
    date: DateTime.parse(json['date'] as String),
    lunarDay: (json['lunar_day'] as num?)?.toInt(),
    title: json['title'] as String? ?? '',
    kind: kind,
    eventId: id,
    sourceName: source?['name'] as String?,
    sourceAvatarUrl: source?['avatar_url'] as String?,
    allDay: json['all_day'] as bool? ?? false,
    startsAt: _parseLocal(json['starts_at']),
    startDate: _parseLocal(json['start_date']),
    endDate: _parseLocal(json['end_date']),
    repeat: PersonalRepeat.fromApi(json['repeat'] as String?),
    repeatDay: (json['repeat_day'] as num?)?.toInt(),
  );
}

DateTime? _parseLocal(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

PersonalCalendarEvent personalEventFromJson(Map<String, dynamic> json) {
  return PersonalCalendarEvent(
    id: json['id'] as String,
    title: json['title'] as String,
    startDate: DateTime.parse(json['start_date'] as String),
    repeat:
        PersonalRepeat.fromApi(json['repeat'] as String?) ??
        PersonalRepeat.none,
    day: (json['day'] as num?)?.toInt(),
  );
}

/// `GET /users/me/calendar-events/repeat-options`. Options the app doesn't know
/// are dropped, since it couldn't save them back.
List<PersonalRepeatOption> repeatOptionsFromJson(Map<String, dynamic> json) {
  final options = <PersonalRepeatOption>[];
  for (final row
      in (json['options'] as List? ?? const []).cast<Map<String, dynamic>>()) {
    final repeat = PersonalRepeat.fromApi(row['repeat'] as String?);
    if (repeat == null) continue;
    options.add(
      PersonalRepeatOption(
        repeat: repeat,
        day: (row['day'] as num?)?.toInt(),
        month: (row['month'] as num?)?.toInt(),
        dayOfWeek: (row['day_of_week'] as num?)?.toInt(),
        nextDates: [
          for (final date in row['next_dates'] as List? ?? const [])
            DateTime.parse(date as String),
        ],
      ),
    );
  }
  return options;
}
