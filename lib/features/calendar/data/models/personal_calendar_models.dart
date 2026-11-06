import 'package:flutter_pecha/features/calendar/domain/models/calendar_event.dart';
import 'package:flutter_pecha/features/calendar/domain/models/personal_calendar_event.dart';

/// `yyyy-MM-dd`, as the API takes dates.
String formatApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// `GET /users/me/calendar` rows, keeping joined-space events. Lunar days are
/// left out because the app works those out itself, so guests and offline users
/// still see them.
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
  final id = json['id'] as String?;
  if (json['kind'] != 'GROUP_EVENT' || id == null) return null;
  final source = json['source'] as Map<String, dynamic>?;
  return CalendarEvent(
    date: DateTime.parse(json['date'] as String),
    lunarDay: (json['lunar_day'] as num?)?.toInt(),
    title: json['title'] as String? ?? '',
    kind: CalendarEventKind.group,
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
