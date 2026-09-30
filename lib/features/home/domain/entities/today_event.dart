import 'package:timezone/timezone.dart' as tz;

/// A Buddhist observance or festival happening today.
class TodayEvent {
  final String id;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;

  /// IANA zone such as "Asia/Kolkata"; null falls back to device time.
  final String? timezone;

  /// Daily window as "HH:mm" in [timezone]; null means all day.
  final String? startTime;
  final String? endTime;

  const TodayEvent({
    required this.id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.timezone,
    this.startTime,
    this.endTime,
  });

  /// True while [now] is inside the event's dates and its daily window.
  bool isActiveAt(DateTime now) {
    final instant = now.toUtc();
    if (startDate != null && instant.isBefore(startDate!.toUtc())) return false;
    if (endDate != null && instant.isAfter(endDate!.toUtc())) return false;

    final start = _minutesOfDay(startTime);
    final end = _minutesOfDay(endTime);
    if (start == null || end == null || start == end) return true;

    final zoned = _inEventZone(now);
    final current = zoned.hour * 60 + zoned.minute;
    if (start < end) return current >= start && current < end;
    return current >= start || current < end;
  }

  DateTime _inEventZone(DateTime now) {
    final zone = timezone;
    if (zone != null && zone.isNotEmpty) {
      try {
        return tz.TZDateTime.from(now, tz.getLocation(zone));
      } catch (_) {
        // Unknown zone or tz database not loaded; use device time.
      }
    }
    return now.toLocal();
  }

  static int? _minutesOfDay(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }
}
